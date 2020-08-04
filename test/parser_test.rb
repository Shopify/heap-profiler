# frozen_string_literal: true
require "test_helper"

module HeapProfiler
  class ParserTest < Minitest::Test
    def setup
      @native = Parser::Native.new
      @ruby = Parser::Ruby.new
    end

    def test_fast_address_parsing
      %w(0x7f921e8b8190 0x7f922208ff78 0x7f921e8a29d0).each do |address|
        assert_equal address.to_i(16), @native.parse_address(address)
      end
    end

    def test_class_index
      class_index, _ = @native.build_index(fixtures_path('diffed-heap/allocated.heap'))
      assert_equal 1271, class_index.size
      assert_equal "HeapProfiler::Error", class_index[0x7f95860b3e98]

      ruby_class_index, _ = @ruby.build_index(fixtures_path('diffed-heap/allocated.heap'))
      assert_equal 1271, ruby_class_index.size
      assert_equal [], ruby_class_index.values - class_index.values
      assert_equal [], class_index.values - ruby_class_index.values
      assert_equal ruby_class_index, class_index
    end

    def test_string_index
      _, string_index = @native.build_index(fixtures_path('diffed-heap/allocated.heap'))
      assert_equal 27251, string_index.size
      assert_equal "HTTP server toolkit", string_index[0x7f95898b46a8]

      _, ruby_string_index = @ruby.build_index(fixtures_path('diffed-heap/allocated.heap'))
      assert_equal 27251, ruby_string_index.size
      assert_equal [], ruby_string_index.values - string_index.values
      assert_equal [], string_index.values - ruby_string_index.values
      assert_equal ruby_string_index, string_index
    end

    private

    def fixtures_path(subpath)
      File.expand_path(File.join('../fixtures', subpath), __FILE__)
    end
  end
end
