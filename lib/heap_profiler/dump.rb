# frozen_string_literal: true

module HeapProfiler
  class Dump
    class Stats
      attr_accessor :count, :memsize

      def process(object)
        @count += 1
        @memsize += object.fetch(:memsize, 0)
      end

      def initialize
        @count = 0
        @memsize = 0
      end
    end

    class GlobalStats < Stats
      class << self
        def from(dump)
          stats = new
          dump.each_object do |object|
            stats.process(object)
          end
          stats
        end
      end

      def process(object)
        super
        per_type[object[:type]].process(object)
      end

      def per_type
        @per_type = Hash.new { |h, k| h[k] = Stats.new }
      end
    end

    class << self
      def open(dir, name)
        Dump.new(File.join(dir, "#{name}.heap"))
      end
    end

    attr_reader :path

    def initialize(path)
      @path = path
    end

    # ObjectSpace.dump_all itself allocate objects.
    #
    # Before 2.7 it will allocate one String per class to get its name.
    # After 2.7, it only allocate a couple hashes, a file etc.
    #
    # Either way we need to exclude them from the reports
    def diff(other, file)
      each_line_with_address do |line, address|
        file << line unless other.index.include?(address)
      end
    end

    def each_object(since: nil, &block)
      Parser.load_many(path, since: since, &block)
    end

    def stats
      @stats ||= GlobalStats.from(self)
    end

    def size
      @size ||= File.open(path).each_line.count
    end

    def index
      @index ||= Native.addresses_set(path)
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
