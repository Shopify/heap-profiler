#include "ruby.h"

static VALUE rb_heap_dump(VALUE self, VALUE path) {
    puts("Hello");
    return Qtrue;
}

void Init_heap_profiler(void) {
    VALUE rb_mHeapProfiler = rb_const_get(rb_cObject, rb_intern("HeapProfiler"));
    VALUE rb_mHeapProfilerNative = rb_const_get(rb_mHeapProfiler, rb_intern("Native"));
    rb_define_module_function(rb_mHeapProfilerNative, "_dump", rb_heap_dump, 1);
}
