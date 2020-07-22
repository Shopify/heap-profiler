# frozen_string_literal: true

module HeapProfiler
  class CLI
    def initialize(argv)
      @argv = argv
    end

    def run
      if @argv.size == 1 && File.directory?(@argv.first)
        print_report(@argv.first)
        0
      else
        print_usage
        1
      end
    end

    def print_report(report_directory)
      results = Results.new(Analyzer.new(report_directory))
      results.pretty_print(scale_bytes: true, normalize_paths: true)
    end

    def print_usage
      puts "Usage: #{$PROGRAM_NAME} directory"
    end
  end
end
