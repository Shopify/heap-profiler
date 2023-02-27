# frozen_string_literal: true

module HeapProfiler
  class Diff
    class DumpSubset
      def initialize(path, generation)
        @path = path
        @generation = generation
      end

      def each_object(&block)
        Parser.load_many(@path, since: @generation, &block)
      end
    end

    attr_reader :allocated

    def initialize(report_directory)
      @report_directory = report_directory
      @allocated = open_dump('allocated')
      @generation = Integer(File.read(File.join(report_directory, 'generation.info')))
      @generation = nil if @generation == 0
    end

    def allocated_diff
      @allocated_diff ||= DumpSubset.new(@allocated.path, @generation)
    end

    def retained_diff
      @retained_diff ||= DumpSubset.new(open_dump('retained').path, @generation)
    end

    private

    def open_dump(name)
      Dump.open(@report_directory, name)
    end
  end
end
