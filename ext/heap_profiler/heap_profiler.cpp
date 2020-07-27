#include "ruby.h"
#include "simdjson.h"

using namespace simdjson;

static VALUE rb_eHeapProfilerError, sym_type, sym_class, sym_address, sym_value,
             sym_memsize, sym_imemo_type, sym_struct, sym_file, sym_line, sym_shared,
             sym_references;

const uint64_t digittoval[256] = {
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  2,  3,  4,  5,  6,  7,  8,
     9,  0,  0,  0,  0,  0,  0,  0, 10, 11, 12, 13, 14, 15,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0, 10, 11, 12, 13, 14, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0};

// Inspired by https://lemire.me/blog/2019/04/17/parsing-short-hexadecimal-strings-efficiently/
// Ruby addresses in heap dump are hexadecimal strings "0x000000000000"...0xffffffffffff".
// The format being fairly stable allow for faster parsing. It should be equivalent to String#to_i(16).
static inline uint64_t parse_address(const char * address) {
    return (
        digittoval[address[ 2]] << 44 |
        digittoval[address[ 3]] << 40 |
        digittoval[address[ 4]] << 36 |
        digittoval[address[ 5]] << 32 |
        digittoval[address[ 6]] << 28 |
        digittoval[address[ 7]] << 24 |
        digittoval[address[ 8]] << 20 |
        digittoval[address[ 9]] << 16 |
        digittoval[address[10]] << 12 |
        digittoval[address[11]] <<  8 |
        digittoval[address[12]] <<  4 |
        digittoval[address[13]]
    );
}

static inline int64_t parse_address(dom::element element) {
    std::string_view address;
    if (element.get(address)) {
        return 0; // ROOT object
    }
    assert(address.size() == 14);
    return parse_address(address.data());
}

static VALUE rb_heap_build_index(VALUE self, VALUE path, VALUE batch_size) {
    Check_Type(path, T_STRING);
    Check_Type(batch_size, T_FIXNUM);

    VALUE string_index = rb_hash_new();
    VALUE class_index = rb_hash_new();

    try {
        dom::parser parser;
        auto [objects, error] = parser.load_many(RSTRING_PTR(path), FIX2INT(batch_size));
        if (error != SUCCESS) {
            rb_raise(rb_eHeapProfilerError, "%s", error_message(error));
        }

        for (dom::object object : objects) {
            std::string_view type;
            if (object["type"].get(type)) {
                continue;
            }

            if (type == "STRING") {
                std::string_view value;
                if (!object["value"].get(value)) {
                    VALUE address = INT2FIX(parse_address(object["address"]));
                    VALUE string = rb_utf8_str_new(value.data(), value.size());
                    rb_hash_aset(string_index, address, string);
                }
            } else if (type == "CLASS" || type == "MODULE") {
                std::string_view name;
                if (!object["name"].get(name)) {
                    VALUE address = INT2FIX(parse_address(object["address"]));
                    VALUE class_name = rb_utf8_str_new(name.data(), name.size());
                    rb_hash_aset(class_index, address, class_name);
                }
            }
        }
    }
    catch (simdjson::simdjson_error error)
    {
        rb_raise(rb_eHeapProfilerError, "exc: %s", error.what());
    }

    VALUE return_value = rb_ary_new();
    rb_ary_push(return_value, class_index);
    rb_ary_push(return_value, string_index);
    return return_value;
}

static VALUE rb_heap_parse_address(VALUE self, VALUE address) {
    Check_Type(address, T_STRING);
    assert(RSTRING_LEN(address) == 14);
    return INT2FIX(parse_address(RSTRING_PTR(address)));
}

static VALUE make_ruby_object(dom::object object)
{
    VALUE hash = rb_hash_new();

    std::string_view type;
    if (!object["type"].get(type)) {
        rb_hash_aset(hash, sym_type, rb_utf8_str_new(type.data(), type.size()));
    }

    std::string_view address;
    if (!object["address"].get(address)) {
        rb_hash_aset(hash, sym_address, INT2FIX(parse_address(address.data())));
    }

    std::string_view _class;
    if (!object["class"].get(_class)) {
        rb_hash_aset(hash, sym_class, INT2FIX(parse_address(_class.data())));
    }

    uint64_t memsize;
    if (!object["memsize"].get(memsize)) {
        rb_hash_aset(hash, sym_memsize, INT2FIX(memsize));
    }

    if (type == "IMEMO") {
        std::string_view imemo_type;
        if (!object["imemo_type"].get(imemo_type)) {
            rb_hash_aset(hash, sym_imemo_type, rb_utf8_str_new(imemo_type.data(), imemo_type.size()));
        }
    } else if (type == "DATA") {
        std::string_view _struct;
        if (!object["struct"].get(_struct)) {
            rb_hash_aset(hash, sym_struct, rb_utf8_str_new(_struct.data(), _struct.size()));
        }
    } else if (type == "STRING") {
        std::string_view value;
        if (!object["value"].get(value)) {
            rb_hash_aset(hash, sym_value, rb_utf8_str_new(value.data(), value.size()));
        }

        bool shared;
        if (!object["shared"].get(shared)) {
            rb_hash_aset(hash, sym_shared, shared ? Qtrue : Qnil);
            if (shared) {
                VALUE references = rb_ary_new();
                dom::array reference_elements(object["references"]);
                for (dom::element reference_element : reference_elements) {
                    std::string_view reference;
                    if (!reference_element.get(reference)) {
                        rb_ary_push(references, INT2FIX(parse_address(reference.data())));
                    }
                }
                rb_hash_aset(hash, sym_references, references);
            }
        }
    }

    std::string_view file;
    if (!object["file"].get(file)) {
        rb_hash_aset(hash, sym_file, rb_utf8_str_new(file.data(), file.size()));
    }

    uint64_t line;
    if (!object["line"].get(line)) {
        rb_hash_aset(hash, sym_line, INT2FIX(line));
    }

    return hash;
}

static VALUE rb_heap_load_many(VALUE self, VALUE arg, VALUE batch_size)
{
    Check_Type(arg, T_STRING);
    Check_Type(batch_size, T_FIXNUM);

    try
    {
        dom::parser parser;
        auto [docs, error] = parser.load_many(RSTRING_PTR(arg), FIX2INT(batch_size));
        if (error != SUCCESS)
        {
            rb_raise(rb_eHeapProfilerError, "%s", error_message(error));
        }

        for (dom::element doc : docs)
        {
            rb_yield(make_ruby_object(doc));
        }

        return Qnil;
    }
    catch (simdjson::simdjson_error error)
    {
        rb_raise(rb_eHeapProfilerError, "%s", error.what());
    }
}

extern "C" {
    void Init_heap_profiler(void) {
        sym_type = ID2SYM(rb_intern("type"));
        sym_class = ID2SYM(rb_intern("class"));
        sym_address = ID2SYM(rb_intern("address"));
        sym_value = ID2SYM(rb_intern("value"));
        sym_memsize = ID2SYM(rb_intern("memsize"));
        sym_struct = ID2SYM(rb_intern("struct"));
        sym_imemo_type = ID2SYM(rb_intern("imemo_type"));
        sym_file = ID2SYM(rb_intern("file"));
        sym_line = ID2SYM(rb_intern("line"));
        sym_shared = ID2SYM(rb_intern("shared"));
        sym_references = ID2SYM(rb_intern("references"));

        VALUE rb_mHeapProfiler = rb_const_get(rb_cObject, rb_intern("HeapProfiler"));
        VALUE rb_mHeapProfilerNative = rb_const_get(rb_mHeapProfiler, rb_intern("Native"));

        rb_eHeapProfilerError = rb_const_get(rb_mHeapProfiler, rb_intern("Error"));
        rb_global_variable(&rb_eHeapProfilerError);

        rb_define_module_function(rb_mHeapProfilerNative, "_build_index", reinterpret_cast<VALUE (*)(...)>(rb_heap_build_index), 2);
        rb_define_module_function(rb_mHeapProfilerNative, "parse_address", reinterpret_cast<VALUE (*)(...)>(rb_heap_parse_address), 1);
        rb_define_module_function(rb_mHeapProfilerNative, "_load_many", reinterpret_cast<VALUE (*)(...)>(rb_heap_load_many), 2);
    }
}
