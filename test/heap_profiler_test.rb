# frozen_string_literal: true
require "test_helper"

class HeapProfilerTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Heap::Profiler::VERSION
  end

  def test_report_dump_three_heaps
    Dir.mktmpdir do |dir|
      HeapProfiler.report(dir) {}
      assert_equal %w(allocated.heap baseline.heap retained.heap), Dir['*', base: dir].sort
    end
  end
end
