# frozen_string_literal: true
require "test_helper"

module HeapProfiler
  class IndexTest < Minitest::Test
    def setup
      @index = Index.new(Dump.new(fixtures_path('ruby-3.0-singleton-classes.heap')))
    end

    def test_guess_data_type_class
      assert_equal '<something> (DATA)', @index.guess_class({ type: :DATA, struct: :something })
    end

    private

    def fixtures_path(subpath)
      File.expand_path(File.join('../fixtures', subpath), __FILE__)
    end
  end
end
