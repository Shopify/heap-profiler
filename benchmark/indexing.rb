#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "benchmark/ips"
require "heap_profiler/full"

FIXTURE_PATH = File.expand_path("../../test/fixtures/diffed-heap/allocated.heap", __FILE__)

native = HeapProfiler::Parser::Native.new
ruby = HeapProfiler::Parser::Ruby.new

Benchmark.ips do |x|
  x.report("ruby") { ruby.build_index(FIXTURE_PATH) }
  x.report("cpp") { native.build_index(FIXTURE_PATH) }
  x.compare!
end
