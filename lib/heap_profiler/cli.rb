# frozen_string_literal: true

module HeapProfiler
  class CLI
    def initialize(argv)
      @argv = argv
    end

    def run
      if @argv.size == 1
        print_report(@argv.first)
        0
      else
        print_usage
        1
      end
    end

    def print_report(path)
      results = if File.directory?(path)
        DiffResults.new(path)
      else
        HeapResults.new(path)
      end
      results.pretty_print(scale_bytes: true, normalize_paths: true)
    end

    def print_usage
      puts "Usage: #{$PROGRAM_NAME} directory_or_heap_dump"
    end
  end
end
