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
        assert_equal 0, data['total'].objects
        assert_equal 0, data['total'].memory
      end
    end

    def test_total_object_counts
      analyser = build_analyzer('diffed-heap')
      data = analyser.run(%w(objects memory), [])
      assert_equal 36, data['total'].objects
      assert_equal 3_717, data['total'].memory
    end

    def test_total_per_gem_counts
      analyser = build_analyzer('diffed-heap')
      data = analyser.run(%w(objects), %w(gem))
      assert_equal({ "other" => 36 }, data['gem'].objects)
    end

    def test_total_per_class_counts
      analyser = build_analyzer('diffed-heap')
      data = analyser.run(%w(objects), %w(class))
      expected = {
        "String" => 12,
        "Array" => 4,
        "Date" => 1,
        "SomeCustomStuff" => 1,
        "<ment> (IMEMO)" => 8,
        "<ifunc> (IMEMO)" => 2,
        "Class" => 2,
        "Hash" => 1,
        "Symbol" => 1,
        "<cref> (IMEMO)" => 2,
        "<iseq> (IMEMO)" => 2,
      }
      assert_equal expected, data['class'].objects
    end

    private

    def build_analyzer(report_path, type = 'allocated')
      diff = Diff.new(fixtures_path(report_path))
      heap = diff.public_send("#{type}_diff")
      Analyzer.new(heap, Index.new(diff.allocated))
    end

    def fixtures_path(subpath)
      File.expand_path(File.join('../fixtures', subpath), __FILE__)
    end
  end
end
