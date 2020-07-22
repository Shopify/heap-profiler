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
        assert_equal 0, analyser.total_allocated
        assert_equal 0, analyser.total_allocated_memsize
        assert_equal 0, analyser.total_retained
        assert_equal 0, analyser.total_retained_memsize
        # TODO: figure a way to make freed stats reliable
        # assert_equal 0, analyser.total_freed
        # assert_equal 0, analyser.total_freed_memsize
      end
    end

    def test_allocated_objects_count
      with_analyser(:simple_allocations) do |analyser|
        assert_equal 10, analyser.total_allocated
      end
    end

    def test_retained_objects_count
      with_analyser(:simple_retention) do |analyser|
        assert_equal 6, analyser.total_retained, -> { File.read(analyser.retained.path) }
      end
    end

    def test_freeed_objects_count
      ObjectSpace.dump_all(output: File.open(File::NULL, 'w'))
      simple_retention
      with_analyser(:simple_free) do |analyser|
        assert_equal 6, analyser.total_freed, -> { File.read(analyser.freed.path) }
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
