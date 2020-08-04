# frozen_string_literal: true

module HeapProfiler
  class Diff
    class LazyDump
      def initialize(&block)
        @thread = Thread.new(&block)
        @thread.abort_on_exception = true
      end

      def each_object(&block)
        @dump ||= @thread.join.value
        @dump.each_object(&block)
      end
    end

    attr_reader :allocated

    def initialize(report_directory)
      @report_directory = report_directory
      @allocated = open_dump('allocated')
      @generation = Integer(File.read(File.join(report_directory, 'generation.info')))
    end

    def allocated_diff
      @allocated_diff ||= build_diff('allocated-diff', @allocated)
    end

    def retained_diff
      @retained_diff ||= build_diff('retained-diff', open_dump('retained'))
    end

    private

    def build_diff(name, base)
      LazyDump.new do
        diff = open_dump(name)
        unless diff.exist?
          base.filter(File.join(@report_directory, "#{name}.heap"), since: @generation)
        end
        diff
      end
    end

    def open_dump(name)
      Dump.open(@report_directory, name)
    end
  end
end
