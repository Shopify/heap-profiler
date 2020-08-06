#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "heap_profiler/full"

HeapProfiler::Parser.filter_heap(ARGV.first, "#{ARGV.first}.diff", Integer(ARGV[1]))
