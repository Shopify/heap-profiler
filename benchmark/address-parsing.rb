#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "benchmark/ips"
require "heap_profiler/full"

Benchmark.ips do |x|
  x.report("ruby") { HeapProfiler::Native.ruby_parse_address("0x7f921e88a8f8") }
  x.report("cpp") { HeapProfiler::Native.parse_address("0x7f921e88a8f8") }
  x.compare!
end
