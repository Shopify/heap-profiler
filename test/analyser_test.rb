# frozen_string_literal: true
require "test_helper"

module HeapProfiler
  class AnalyserTest < Minitest::Test
    def setup
      @retainer = {}
    end

    def teardown
      @retainer = nil
    end

    def test_empty_report
      with_analyser(:noop) do |analyser|
        assert_equal 0, analyser.allocated_objects_count
      end
    end

    def test_allocated_objects_count
      with_analyser(:simple_allocations) do |analyser|
        assert_equal 10, analyser.allocated_objects_count
      end
    end

    def test_retained_objects_count
      with_analyser(:simple_retention) do |analyser|
        assert_equal 6, analyser.retained_objects_count, -> { File.read(analyser.retained_diff.path) }
      end
    end

    def test_freeed_objects_count
      ObjectSpace.dump_all(output: File.open(File::NULL, 'w'))
      simple_retention
      with_analyser(:simple_free) do |analyser|
        assert_equal 6, analyser.freed_objects_count, -> { File.read(analyser.freed_diff.path) }
      end
    end

    private

    def with_analyser(method)
      with_tmpdir do |dir|
        HeapProfiler.report(dir) do
          send(method)
        end
        yield Analyzer.new(dir)
      end
    end

    def with_tmpdir(&block)
      if ENV['KEEP_PROFILE']
        dir = "/tmp/heap-profiler-debug"
        FileUtils.mkdir_p(dir)
        FileUtils.rm_rf(Dir[File.join(dir, "*")])
        yield dir
      else
        Dir.mktmpdir(&block)
      end
    end

    def simple_allocations
      5.times { {} }
      5.times { [] }
    end

    def noop
    end

    def simple_retention
      @retainer[:simple] = 5.times.map { {} }
    end

    def simple_free
      @retainer.delete(:simple)
    end
  end
end
