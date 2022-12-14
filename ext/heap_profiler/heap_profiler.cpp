#include "ruby.h"
#include "ruby/encoding.h"
#include "simdjson.h"
#include <fstream>

using namespace simdjson;

static VALUE rb_eHeapProfilerError, rb_eHeapProfilerCapacityError, sym_type, sym_class,
             sym_address, sym_value, sym_memsize, sym_imemo_type, sym_struct, sym_file,
             sym_line, sym_shared, sym_references, sym_edge_name, id_uminus;

typedef struct {
    dom::parser *parser;
} parser_t;

static void Parser_delete(void *ptr) {
    parser_t *data = (parser_t*) ptr;
    delete data->parser;
}

static size_t Parser_memsize(const void *parser) {
    return sizeof(dom::parser); // TODO: low priority, figure the real size, e.g. internal buffers etc.
}

static const rb_data_type_t parser_data_type = {
    "Parser",
    { 0, Parser_delete, Parser_memsize, },
    0, 0, RUBY_TYPED_FREE_IMMEDIATELY
};

static VALUE parser_allocate(VALUE klass) {
    parser_t *data;
    VALUE obj = TypedData_Make_Struct(klass, parser_t, &parser_data_type, data);
    data->parser = new dom::parser;
    return obj;
}

static inline dom::parser * get_parser(VALUE self) {
    parser_t *data;
    TypedData_Get_Struct(self, parser_t, &parser_data_type, data);
    return data->parser;
}

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
static inline uint64_t parse_address(const char * address, const long size) {
    assert(address[0] == '0');
    assert(address[1] == 'x');

    uint64_t value = 0;
    for (int index = 2; index < size; index++) {
        value <<= 4;
        value |= digittoval[address[index]];
    }
    return value;
}

static inline int64_t parse_address(std::string_view address) {
    return parse_address(address.data(), address.size());
}

static inline int64_t parse_dom_address(dom::element element) {
    std::string_view address;
    if (element.get(address)) {
        return 0; // ROOT object
    }
    return parse_address(address);
}

static inline VALUE make_symbol(std::string_view string) {
    return ID2SYM(rb_intern2(string.data(), string.size()));
}

static inline VALUE make_string(std::string_view string) {
    return rb_utf8_str_new(string.data(), string.size());
}

# ifdef HAVE_RB_ENC_INTERNED_STR
    static inline VALUE dedup_string(std::string_view string) {
        return rb_enc_interned_str(string.data(), string.size(), rb_utf8_encoding());
    }
# else
    static inline VALUE dedup_string(std::string_view string) {
        return rb_funcall(make_string(string), id_uminus, 0);
    }
# endif

static VALUE rb_heap_build_index(VALUE self, VALUE path, VALUE batch_size) {
    Check_Type(path, T_STRING);
    Check_Type(batch_size, T_FIXNUM);
    dom::parser *parser = get_parser(self);
    dom::document_stream objects;

    VALUE string_index = rb_hash_new();
    VALUE class_index = rb_hash_new();

    try {
        auto error = parser->load_many(RSTRING_PTR(path), FIX2INT(batch_size)).get(objects);
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
                    VALUE address = INT2FIX(parse_dom_address(object["address"]));
                    VALUE string = make_string(value);
                    rb_hash_aset(string_index, address, string);
                }
            } else if (type == "CLASS" || type == "MODULE") {
                VALUE address = INT2FIX(parse_dom_address(object["address"]));
                VALUE class_name = Qfalse;

                std::string_view name;
                if (!object["name"].get(name)) {
                    class_name = dedup_string(name);
                } else {
                    std::string_view file;
                    uint64_t line;

                    if (!object["file"].get(file) && !object["line"].get(line)) {
                        std::string buffer = "<Class ";
                        buffer += file;
                        buffer += ":";
                        buffer += std::to_string(line);
                        buffer += ">";
                        class_name = dedup_string(buffer);
                    }
                }

                if (RTEST(class_name)) {
                    rb_hash_aset(class_index, address, class_name);
                }
            }
        }
    } catch (simdjson::simdjson_error error) {
        if (error.error() == CAPACITY) {
            rb_raise(rb_eHeapProfilerCapacityError, "The parser batch size is too small to parse this heap dump");
        } else {
            rb_raise(rb_eHeapProfilerError, "exc: %s", error.what());
        }
    }

    VALUE return_value = rb_ary_new();
    rb_ary_push(return_value, class_index);
    rb_ary_push(return_value, string_index);
    return return_value;
}

static VALUE rb_heap_parse_address(VALUE self, VALUE address) {
    Check_Type(address, T_STRING);
    return INT2FIX(parse_address(RSTRING_PTR(address), RSTRING_LEN(address)));
}

static VALUE make_ruby_object(dom::object object)
{
    VALUE hash = rb_hash_new();

    std::string_view type;
    if (!object["type"].get(type)) {
        rb_hash_aset(hash, sym_type, make_symbol(type));
    }

    std::string_view address;
    if (!object["address"].get(address)) {
        rb_hash_aset(hash, sym_address, INT2FIX(parse_address(address)));
    }

    std::string_view _class;
    if (type != "IMEMO") {
        // IMEMO "class" field can sometime be junk
        if (!object["class"].get(_class)) {
            rb_hash_aset(hash, sym_class, INT2FIX(parse_address(_class)));
        }
    }

    uint64_t memsize;
    if (object["memsize"].get(memsize)) {
        // ROOT object
        rb_hash_aset(hash, sym_memsize, INT2FIX(0));
    } else {
        rb_hash_aset(hash, sym_memsize, INT2FIX(memsize));
    }

    if (type == "IMEMO") {
        std::string_view imemo_type;
        if (!object["imemo_type"].get(imemo_type)) {
            rb_hash_aset(hash, sym_imemo_type, make_symbol(imemo_type));
        }
    } else if (type == "DATA") {
        std::string_view _struct;
        if (!object["struct"].get(_struct)) {
            rb_hash_aset(hash, sym_struct, make_symbol(_struct));
        }
    } else if (type == "STRING") {
        std::string_view value;
        if (!object["value"].get(value)) {
            rb_hash_aset(hash, sym_value, make_string(value));
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
                        rb_ary_push(references, INT2FIX(parse_address(reference)));
                    }
                }
                rb_hash_aset(hash, sym_references, references);
            }
        }
    } else if (type == "SHAPE") {
        std::string_view edge_name;
        if (!object["edge_name"].get(edge_name)) {
            rb_hash_aset(hash, sym_edge_name, make_string(edge_name));
        }
    }

    std::string_view file;
    if (!object["file"].get(file)) {
        rb_hash_aset(hash, sym_file, dedup_string(file));
    }

    uint64_t line;
    if (!object["line"].get(line)) {
        rb_hash_aset(hash, sym_line, INT2FIX(line));
    }

    return hash;
}

static VALUE rb_heap_load_many(VALUE self, VALUE arg, VALUE since, VALUE batch_size)
{
    Check_Type(arg, T_STRING);
    Check_Type(batch_size, T_FIXNUM);

    dom::parser *parser = get_parser(self);
    dom::document_stream objects;
    try {
        auto error = parser->load_many(RSTRING_PTR(arg), FIX2INT(batch_size)).get(objects);
        if (error != SUCCESS) {
            rb_raise(rb_eHeapProfilerError, "%s", error_message(error));
        }

        int64_t generation = -1;
        if (RTEST(since)) {
            Check_Type(since, T_FIXNUM);
            generation = FIX2INT(since);
        }

        for (dom::element object : objects) {
            int64_t object_generation;
            if (generation > -1 && object["generation"].get(object_generation) || object_generation < generation) {
                continue;
            }

            std::string_view property;
            if (!object["file"].get(property) && property == "__hprof") {
                continue;
            }
            if (!object["struct"].get(property) && property == "ObjectTracing/allocation_info_tracer") {
                continue;
            }

            rb_yield(make_ruby_object(object));
        }

        return Qnil;
    } catch (simdjson::simdjson_error error) {
        if (error.error() == CAPACITY) {
            rb_raise(rb_eHeapProfilerCapacityError, "The parser batch size is too small to parse this heap dump");
        } else {
            rb_raise(rb_eHeapProfilerError, "exc: %s", error.what());
        }
    }
}

extern "C" {
    void Init_heap_profiler(void) {
        sym_type = ID2SYM(rb_intern("type"));
        sym_class = ID2SYM(rb_intern("class"));
        sym_address = ID2SYM(rb_intern("address"));
        sym_edge_name = ID2SYM(rb_intern("edge_name"));
        sym_value = ID2SYM(rb_intern("value"));
        sym_memsize = ID2SYM(rb_intern("memsize"));
        sym_struct = ID2SYM(rb_intern("struct"));
        sym_imemo_type = ID2SYM(rb_intern("imemo_type"));
        sym_file = ID2SYM(rb_intern("file"));
        sym_line = ID2SYM(rb_intern("line"));
        sym_shared = ID2SYM(rb_intern("shared"));
        sym_references = ID2SYM(rb_intern("references"));
        id_uminus = rb_intern("-@");

        VALUE rb_mHeapProfiler = rb_const_get(rb_cObject, rb_intern("HeapProfiler"));

        rb_eHeapProfilerError = rb_const_get(rb_mHeapProfiler, rb_intern("Error"));
        rb_global_variable(&rb_eHeapProfilerError);

        rb_eHeapProfilerCapacityError = rb_const_get(rb_mHeapProfiler, rb_intern("CapacityError"));
        rb_global_variable(&rb_eHeapProfilerCapacityError);

        VALUE rb_mHeapProfilerParserNative = rb_const_get(rb_const_get(rb_mHeapProfiler, rb_intern("Parser")), rb_intern("Native"));
        rb_define_alloc_func(rb_mHeapProfilerParserNative, parser_allocate);
        rb_define_method(rb_mHeapProfilerParserNative, "_build_index", reinterpret_cast<VALUE (*)(...)>(rb_heap_build_index), 2);
        rb_define_method(rb_mHeapProfilerParserNative, "parse_address", reinterpret_cast<VALUE (*)(...)>(rb_heap_parse_address), 1);
        rb_define_method(rb_mHeapProfilerParserNative, "_load_many", reinterpret_cast<VALUE (*)(...)>(rb_heap_load_many), 3);
    }
}
