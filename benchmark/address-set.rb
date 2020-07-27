#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "benchmark/ips"
require "heap_profiler/full"

FIXTURE_PATH = File.expand_path("../../test/fixtures/diffed-heap/allocated.heap", __FILE__)

Benchmark.ips do |x|
  x.report("ruby") { HeapProfiler::Native.ruby_addresses_set(FIXTURE_PATH) }
  x.report("cpp") { HeapProfiler::Native.addresses_set(FIXTURE_PATH) }
  x.compare!
end
