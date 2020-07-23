# frozen_string_literal: true

module HeapProfiler
  class Diff
    attr_reader :allocated

    def initialize(report_directory)
      @report_directory = report_directory
      @baseline = open_dump('baseline')
      @allocated = open_dump('allocated')
      @retained = open_dump('retained')
    end

    def allocated_diff
      @allocated_diff ||= build_diff('allocated-diff', @baseline, @allocated)
    end

    def retained_diff
      @retained_diff ||= build_diff('retained-diff', @baseline, @retained)
    end

    def freed_diff
      @freed_diff ||= build_diff('freed-diff', @retained, @baseline)
    end

    private

    def build_diff(name, base, extra)
      diff = open_dump(name)
      unless diff.exist?
        File.open(diff.path, 'w+') do |f|
          extra.diff(base, f)
        end
      end
      diff
    end

    def open_dump(name)
      Dump.open(@report_directory, name)
    end
  end
end
