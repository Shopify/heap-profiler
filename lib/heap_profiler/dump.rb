# frozen_string_literal: true

module HeapProfiler
  class Dump
    class << self
      def open(dir, name)
        Dump.new(File.join(dir, "#{name}.heap"))
      end
    end

    attr_reader :path

    def initialize(path)
      @path = path
    end

    def diff(other, file)
      each_line_with_address do |line, address|
        file << line unless other.index.include?(address)
      end
    end

    def size
      @size ||= File.open(path).each_line.count
    end

    def index
      @index ||= Set.new.tap do |index|
        each_line_with_address do |_line, address|
          index << address
        end
      end
    end

    def each_line_with_address
      File.open(path).each_line do |line|
        # This is a cheap, hacky extraction of addresses.
        # So far it seems to work on 2.7.1 but that might not hold true on all versions.
        # Also the root objects don't have an address, but that's fine
        yield line, line.byteslice(14, 12).to_i(16)
      end
    end

    def exist?
      File.exist?(@path)
    end

    def presence
      exist? ? self : nil
    end
  end
end
