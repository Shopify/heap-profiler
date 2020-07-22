# frozen_string_literal: true

module HeapProfiler
  module Monochrome
    class << self
      def path(text)
        text
      end

      def string(text)
        text
      end

      def line(text)
        text
      end
    end
  end
end
