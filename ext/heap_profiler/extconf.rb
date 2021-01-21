# frozen_string_literal: true

require "mkmf"

have_func("rb_enc_interned_str", "ruby.h")

$CXXFLAGS += ' -O3 -std=c++1z -Wno-register '

create_makefile 'heap_profiler/heap_profiler'
