# frozen_string_literal: true

module HeapProfiler
  module Parser
    CLASS_DEFAULT_PROC = ->(_hash, key) { "<Class#0x#{key.to_s(16)}>" }

    class << self
      attr_accessor :batch_size
    end
    self.batch_size = 10_000_000 # 10MB

    class Ruby
      def build_index(path)
        require 'json'
        classes_index = {}
        classes_index.default_proc = CLASS_DEFAULT_PROC
        strings_index = {}

        File.open(path).each_line do |line|
          object = JSON.parse(line, symbolize_names: true)
          case object[:type]
          when 'MODULE', 'CLASS'
            address = parse_address(object[:address])

            name = object[:name]
            name ||= if object[:file] && object[:line]
              "<Class #{object[:file]}:#{object[:line]}>"
            end

            if name
              classes_index[address] = name
            end
          when 'STRING'
            next if object[:shared]
            if (value = object[:value])
              strings_index[parse_address(object[:address])] = value
            end
          end
        end

        [classes_index, strings_index]
      end

      def parse_address(address)
        address.to_i(16)
      end
    end

    class Native
      def build_index(path, batch_size: Parser.batch_size)
        indexes = _build_index(path, batch_size)
        indexes.first.default_proc = CLASS_DEFAULT_PROC
        indexes
      end

      def load_many(path, since: nil, batch_size: Parser.batch_size, &block)
        _load_many(path, since, batch_size, &block)
      end
    end

    class << self
      def build_index(path)
        current.build_index(path)
      end

      def load_many(path, **kwargs, &block)
        current.load_many(path, **kwargs, &block)
      end

      private

      def current
        Thread.current[:HeapProfilerParser] ||= Native.new
      end
    end
  end
  require "heap_profiler/heap_profiler"
end
