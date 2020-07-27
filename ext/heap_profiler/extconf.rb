# frozen_string_literal: true

require "mkmf"

$CXXFLAGS += ' -std=c++1z -Wno-register '

create_makefile 'heap_profiler/heap_profiler'
