// #include "ruby.h"
// #include "simdjson.h"

// using namespace simdjson;

// static VALUE rb_eHeapProfilerError;
//
// static VALUE make_ruby_object(dom::element element, bool symbolize_keys)
// {
//     switch (element.type())
//     {
//     case dom::element_type::ARRAY:
//     {
//         VALUE ary = rb_ary_new();
//         for (dom::element x : element)
//         {
//             VALUE e = make_ruby_object(x, symbolize_keys);
//             rb_ary_push(ary, e);
//         }
//         return ary;
//     }
//     case dom::element_type::OBJECT:
//     {
//         VALUE hash = rb_hash_new();
//         for (dom::key_value_pair field : dom::object(element))
//         {
//             std::string_view view(field.key);
//             VALUE k = rb_utf8_str_new(view.data(), view.size());
//             if (symbolize_keys)
//             {
//                 k = ID2SYM(rb_intern_str(k));
//             }
//             VALUE v = make_ruby_object(field.value, symbolize_keys);
//             rb_hash_aset(hash, k, v);
//         }
//         return hash;
//     }
//     case dom::element_type::INT64:
//     {
//         return LONG2NUM(element.get<int64_t>());
//     }
//     case dom::element_type::UINT64:
//     {
//         return ULONG2NUM(element.get<uint64_t>());
//     }
//     case dom::element_type::DOUBLE:
//     {
//         return DBL2NUM(double(element));
//     }
//     case dom::element_type::STRING:
//     {
//         std::string_view view(element);
//         return rb_utf8_str_new(view.data(), view.size());
//     }
//     case dom::element_type::BOOL:
//     {
//         return bool(element) ? Qtrue : Qfalse;
//     }
//     case dom::element_type::NULL_VALUE:
//     {
//         return Qnil;
//     }
//     }
//     // unknown case (bug)
//     rb_raise(rb_eException, "[BUG] must not happen");
// }
//
// const uint64_t digittoval[256] = {
//      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
//      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
//      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  2,  3,  4,  5,  6,  7,  8,
//      9,  0,  0,  0,  0,  0,  0,  0, 10, 11, 12, 13, 14, 15,  0,  0,  0,  0,  0,
//      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
//      0,  0, 10, 11, 12, 13, 14, 15,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
//      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
//      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
//      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
//      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
//      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
//      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
//      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
//      0,  0,  0,  0,  0,  0,  0,  0,  0};
//
// // Inspired by https://lemire.me/blog/2019/04/17/parsing-short-hexadecimal-strings-efficiently/
// // Ruby addresses in heap dump are hexadecimal strings "0x000000000000"...0xffffffffffff".
// // The format being fairly stable allow for faster parsing. It should be equivalent to String#to_i(16).
// static inline uint64_t parse_address(const char * address) {
//     return (
//         digittoval[address[ 2]] << 44 |
//         digittoval[address[ 3]] << 40 |
//         digittoval[address[ 4]] << 36 |
//         digittoval[address[ 5]] << 32 |
//         digittoval[address[ 6]] << 28 |
//         digittoval[address[ 7]] << 24 |
//         digittoval[address[ 8]] << 20 |
//         digittoval[address[ 9]] << 16 |
//         digittoval[address[10]] << 12 |
//         digittoval[address[11]] <<  8 |
//         digittoval[address[12]] <<  4 |
//         digittoval[address[13]]
//     );
// }
//
// static inline int64_t parse_address(dom::element element) {
//     std::string_view address;
//     if (auto error = element.get(address)) {
//         rb_raise(rb_eHeapProfilerError, "parse_address: %s", error_message(error));
//     }
//     assert(address.size() == 14);
//     return parse_address(address.data());
// }
//
// static VALUE rb_heap_build_index(VALUE self, VALUE path, VALUE batch_size) {
//     Check_Type(path, T_STRING);
//     Check_Type(batch_size, T_FIXNUM);
//
//     VALUE string_index = rb_hash_new();
//     VALUE class_index = rb_hash_new();
//
//     try {
//         dom::parser parser;
//         auto [objects, error] = parser.load_many(RSTRING_PTR(path), FIX2INT(batch_size));
//         if (error != SUCCESS) {
//             rb_raise(rb_eHeapProfilerError, "%s", error_message(error));
//         }
//
//         for (dom::object object : objects) {
//             std::string_view type;
//             if (object["type"].get(type)) {
//                 continue;
//             }
//
//             if (type == "STRING") {
//                 bool shared;
//                 std::string_view value;
//                 if (!object["shared"].get(shared) && shared && !object["value"].get(value)) {
//                     rb_hash_aset(string_index, parse_address(object["address"]), rb_utf8_str_new(value.data(), value.size()));
//                 }
//             } else if (type == "CLASS" || type == "MODULE") {
//                 std::string_view name;
//                 if (!object["name"].get(name)) {
//                     rb_hash_aset(class_index, INT2FIX(parse_address(object["address"])), rb_utf8_str_new(name.data(), name.size()));
//                 }
//             }
//         }
//     }
//     catch (simdjson::simdjson_error error)
//     {
//         rb_raise(rb_eHeapProfilerError, "exc: %s", error.what());
//     }
//
//     VALUE return_value = rb_ary_new();
//     rb_ary_push(return_value, class_index);
//     rb_ary_push(return_value, string_index);
//     return return_value;
// }
//
// static VALUE rb_heap_parse_address(VALUE self, VALUE address) {
//     Check_Type(address, T_STRING);
//     assert(RSTRING_LEN(address) == 14);
//     return INT2FIX(parse_address(RSTRING_PTR(address)));
// }

// extern "C" {
//     void Init_heap_profiler(void) {
//         // VALUE rb_mHeapProfiler = rb_const_get(rb_cObject, rb_intern("HeapProfiler"));
//         // VALUE rb_mHeapProfilerNative = rb_const_get(rb_mHeapProfiler, rb_intern("Native"));
//         //
//         // rb_eHeapProfilerError = rb_const_get(rb_mHeapProfiler, rb_intern("Error"));
//         // rb_global_variable(&rb_eHeapProfilerError);
//         //
//         // rb_define_module_function(rb_mHeapProfilerNative, "_build_index", rb_heap_build_index, 2);
//         // rb_define_module_function(rb_mHeapProfilerNative, "parse_address", rb_heap_parse_address, 1);
//     }
// }
