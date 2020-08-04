#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "benchmark/ips"
require "heap_profiler/full"

native = HeapProfiler::Parser::Native.new
ruby = HeapProfiler::Parser::Ruby.new

Benchmark.ips do |x|
  x.report("ruby") { ruby.parse_address("0x7f921e88a8f8") }
  x.report("cpp") { native.parse_address("0x7f921e88a8f8") }
  x.compare!
end
