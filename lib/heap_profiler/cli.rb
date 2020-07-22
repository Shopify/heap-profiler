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
      analyzer = Analyzer.new(report_directory)
      puts "Allocated objects: #{analyzer.allocated_objects_count}"
      puts "Retained objects: #{analyzer.retained_objects_count}"
      puts "Freed objects: #{analyzer.freed_objects_count}"
    end

    def print_usage
      puts "Usage: #{$PROGRAM_NAME} directory"
    end
  end
end
