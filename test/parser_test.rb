# frozen_string_literal: true
require "test_helper"

module HeapProfiler
  class ParserTest < Minitest::Test
    def setup
      @native = Parser::Native.new
      @ruby = Parser::Ruby.new
    end

    def test_fast_address_parsing
      assert_address_parsing '0x0'
      assert_address_parsing '0x7f921e8b8190'
      assert_address_parsing '0x7f922208ff78'
      assert_address_parsing '0x7f921e8a29d0'
      assert_address_parsing '0xffffffffffffff'
      assert_address_parsing '0xFFFFFFFFFFFFFFF'
    end

    def test_class_index
      class_index, _ = @native.build_index(fixtures_path('diffed-heap/allocated.heap'))
      assert_equal 539, class_index.size
      assert_equal "FileUtils", class_index[0x107ca3340]

      ruby_class_index, _ = @ruby.build_index(fixtures_path('diffed-heap/allocated.heap'))
      assert_equal 539, ruby_class_index.size
      assert_equal [], ruby_class_index.values - class_index.values
      assert_equal [], class_index.values - ruby_class_index.values
      assert_equal ruby_class_index, class_index
    end

    def test_string_index
      _, string_index = @native.build_index(fixtures_path('diffed-heap/allocated.heap'))
      assert_equal 24_145, string_index.size
      assert_equal "load_plugins", string_index[0x104c06688]

      _, ruby_string_index = @ruby.build_index(fixtures_path('diffed-heap/allocated.heap'))
      assert_equal 24_145, ruby_string_index.size
      assert_equal [], ruby_string_index.values - string_index.values
      assert_equal [], string_index.values - ruby_string_index.values
      assert_equal ruby_string_index, string_index
    end

    def test_ruby_3_singleton_classes
      class_index, _ = @ruby.build_index(fixtures_path('ruby-3.0-singleton-classes.heap'))
      assert_equal '<Class#0x7ffe49046150>', class_index[0x7ffe49046150]
      assert_equal '<Class /tmp/dump-singleton.rb:8>', class_index[0x7ffe49045ef8]

      class_index, _ = @native.build_index(fixtures_path('ruby-3.0-singleton-classes.heap'))
      assert_equal '<Class#0x7ffe49046150>', class_index[0x7ffe49046150]
      assert_equal '<Class /tmp/dump-singleton.rb:8>', class_index[0x7ffe49045ef8]
    end

    def test_insufficient_batch_size
      previous_batch_size = Parser.batch_size
      Parser.batch_size = 100
      assert_raises CapacityError do
        @native.build_index(fixtures_path('diffed-heap/allocated.heap'))
      end
    ensure
      Parser.batch_size = previous_batch_size
    end

    def test_truncated_final_line_is_dropped
      # A heap dump whose final line is incomplete (a Ruby dump_all bug, issue #12).
      # build_index must terminate and skip the truncated line rather than hang.
      _, string_index = @native.build_index(fixtures_path('truncated-final-line.heap'))
      assert_equal "ok", string_index[0x1]
      refute string_index.key?(0x3)
    end

    def test_malformed_mid_stream_raises
      # A corrupted object mid-stream should raise.
      # The "clean" command would discard this line for the same reason.
      assert_raises(HeapProfiler::Error) do
        @native.build_index(fixtures_path('malformed-mid-stream.heap'))
      end

      assert_raises(HeapProfiler::Error) do
        @native.load_many(fixtures_path('malformed-mid-stream.heap')) {}
      end
    end

    def test_batch_size_splits_docs_and_indexes_and_yields_every_object
      # With batch_size just above the longest line, the file splits across many
      # chunks and most documents straddle a chunk boundary.
      fixture = fixtures_path('multichunk.heap')
      longest = File.readlines(fixture).map(&:bytesize).max
      previous_batch_size = Parser.batch_size
      Parser.batch_size = longest + 16
      begin
        assert File.size(fixture) > Parser.batch_size, "fixture must span multiple chunks"
        _, string_index = @native.build_index(fixture)
        assert_equal 50, string_index.size
        50.times { |i| assert_equal "s#{i}", string_index[i + 1] }

        yielded = 0
        @native.load_many(fixture) { yielded += 1 }
        assert_equal 50, yielded
      ensure
        Parser.batch_size = previous_batch_size
      end
    end

    private

    def assert_address_parsing(address)
      assert_equal address.to_i(16), @native.parse_address(address)
    end

    def fixtures_path(subpath)
      File.expand_path(File.join('../fixtures', subpath), __FILE__)
    end
  end
end
