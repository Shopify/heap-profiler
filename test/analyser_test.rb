# frozen_string_literal: true
require "test_helper"

module HeapProfiler
  class AnalyserTest < Minitest::Test
    def setup
    end

    def teardown
      @retainer = nil
    end

    def test_empty_report
      Tempfile.create do |file|
        heap = Dump.new(file.path)
        analyser = Analyzer.new(heap, Index.new(heap))

        data = analyser.run(%w(objects memory), [])
        assert_equal 0, data['total_objects'].stats
        assert_equal 0, data['total_memory'].stats
      end
    end

    def test_total_object_counts
      analyser = build_analyzer('diffed-heap/allocated-diff.heap', 'diffed-heap/allocated.heap')
      data = analyser.run(%w(objects memory), [])
      assert_equal 38, data['total_objects'].stats
      assert_equal 4_205, data['total_memory'].stats
    end

    def test_total_per_gem_counts
      analyser = build_analyzer('diffed-heap/allocated-diff.heap', 'diffed-heap/allocated.heap')
      data = analyser.run(%w(objects), %w(gem))
      assert_equal({ "other" => 37, "heap-profiler/lib" => 1 }, data['objects_by_gem'].stats)
    end

    def test_total_per_class_counts
      analyser = build_analyzer('diffed-heap/allocated-diff.heap', 'diffed-heap/allocated.heap')
      data = analyser.run(%w(objects), %w(class))
      expected = {
        "String" => 12,
        "Array" => 4,
        "SomeCustomStuff" => 1,
        "Class" => 2,
        "Hash" => 3,
        "Symbol" => 1,
        "<iseq> (IMEMO)" => 2,
        "<ifunc> (IMEMO)" => 2,
        "<ment> (IMEMO)" => 8,
        "<cref> (IMEMO)" => 2,
        "File" => 1,
      }
      assert_equal expected, data['objects_by_class'].stats
    end

    private

    def build_analyzer(heap_path, index_path = heap_path)
      heap = Dump.new(fixtures_path(heap_path))
      if heap_path == index_path
        Analyzer.new(heap, Index.new(heap))
      else
        Analyzer.new(heap, Index.new(Dump.new(fixtures_path(index_path))))
      end
    end

    def fixtures_path(subpath)
      File.expand_path(File.join('../fixtures', subpath), __FILE__)
    end
  end
end
