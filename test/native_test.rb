# frozen_string_literal: true
require "test_helper"

module HeapProfiler
  class NativeTest < Minitest::Test
    def test_fast_address_parsing
      %w(0x7f921e8b8190 0x7f922208ff78 0x7f921e8a29d0).each do |address|
        assert_equal address.to_i(16), Native.parse_address(address)
      end
    end

    def test_class_index
      class_index, _ = Native.build_index(fixtures_path('diffed-heap/allocated.heap'))
      assert_equal 1127, class_index.size
      assert_equal "FileUtils", class_index[140265615232320]

      ruby_class_index, _ = Native.ruby_build_index(fixtures_path('diffed-heap/allocated.heap'))
      assert_equal 1127, ruby_class_index.size
      assert_equal [], ruby_class_index.values - class_index.values
      assert_equal [], class_index.values - ruby_class_index.values
      assert_equal ruby_class_index, class_index
    end

    private

    def fixtures_path(subpath)
      File.expand_path(File.join('../fixtures', subpath), __FILE__)
    end
  end
end
