# frozen_string_literal: true

module HeapProfiler
  module Native
    DEFAULT_BATCH_SIZE = 10_000_000 # 10MB
    class << self
      def build_index(path, batch_size: DEFAULT_BATCH_SIZE)
        _build_index(path, batch_size)
      end

      def addresses_set(path, batch_size: DEFAULT_BATCH_SIZE)
        _addresses_list(path, batch_size)
      end

      def load_many(path, batch_size: DEFAULT_BATCH_SIZE, &block)
        _load_many(path, batch_size, &block)
      end

      def ruby_build_index(path)
        require 'json'
        classes_index = {}
        strings_index = {}

        File.open(path).each_line do |line|
          object = JSON.parse(line, symbolize_names: true)
          case object[:type]
          when 'MODULE', 'CLASS'
            if (name = object[:name])
              classes_index[ruby_parse_address(object[:address])] = name
            end
          when 'STRING'
            next if object[:shared]
            if (value = object[:value])
              strings_index[ruby_parse_address(object[:address])] = value
            end
          end
        end

        [classes_index, strings_index]
      end

      def ruby_addresses_set(path)
        index = Set.new
        File.open(path).each_line do |line|
          # This is a cheap, hacky extraction of addresses.
          # So far it seems to work on 2.7.1 but that might not hold true on all versions.
          # Also the root objects don't have an address, but that's fine
          index << line.byteslice(14, 12).to_i(16)
        end
        index
      end

      def ruby_parse_address(address)
        address.to_i(16)
      end
    end
  end
  require "heap_profiler/heap_profiler"
end
