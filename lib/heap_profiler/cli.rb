# frozen_string_literal: true
require 'optparse'

module HeapProfiler
  class CLI
    def initialize(argv)
      @argv = argv
    end

    def run
      parser.parse!(@argv)

      begin
        case @argv.first
        when "clean"
          clean_dump(@argv[1])
          return 0
        when "report"
          print_report(@argv[1])
          return 0
        else
          if @argv.size == 1
            print_report(@argv.first)
            return 0
          end
        end
      rescue CapacityError => error
        STDERR.puts(error.message)
        STDERR.puts("Current size: #{Parser.batch_size}B")
        STDERR.puts("Try increasing it with --batch-size")
        STDERR.puts
      end
      print_usage
      1
    end

    def print_report(path)
      results = if File.directory?(path)
        if @retained_only
          DiffResults.new(path, ["retained"])
        else
          DiffResults.new(path)
        end
      else
        HeapResults.new(path)
      end
      results.pretty_print(scale_bytes: true, normalize_paths: true)
    end

    def clean_dump(path)
      require "json"
      errors = index = 0
      clean_path = "#{path}.clean"
      File.open(clean_path, "w+") do |output|
        File.open(path) do |input|
          input.each_line do |line|
            begin
              JSON.parse(line)
            rescue JSON::ParserError
              errors += 1
              $stderr.puts("Invalid JSON found on line #{index}. Skipping")
            else
              output.print(line)
            end
            index += 1
          end
        end
      end
      $stderr.puts("Processed #{index} lines, removed #{errors} invalid lines")
      $stderr.puts("Clean dump available at #{clean_path}")
    end

    def print_usage
      puts "Usage: #{$PROGRAM_NAME} directory_or_heap_dump"
      puts @parser.help
    end

    SIZE_UNITS = {
      'B' => 1,
      'K' => 1_000,
      'M' => 1_000_000,
      'G' => 1_000_000_000,
    }
    def parse_byte_size(size_string)
      if (match = size_string.match(/\A(\d+)(\w)?B?\z/i))
        digits = Float(match[1])
        base = 1
        unit = match[2]&.upcase
        if unit
          base = SIZE_UNITS.fetch(unit) { raise ArgumentError, "Unknown size unit: #{unit}" }
        end
        size = (digits * base).to_i
        if size > 4_000_000_000
          raise ArgumentError, "Batch size can't be bigger than 4G"
        end
        size
      else
        raise ArgumentError, "#{size_string} is not a valid size"
      end
    end

    private

    def parser
      @parser ||= OptionParser.new do |opts|
        opts.banner = <<~EOS
          Usage: heap-profiler [SUBCOMMAND] [ARGS]"

          SUBCOMMANDS

            report: Produce a full memory report from the provided dump. (default)

            clean: Remove all malformed lines from the provided heap dump. Can be useful to workaround some ruby bugs.

          GLOBAL OPTIONS
        EOS
        opts.separator ""

        opts.on('-r', '--retained-only', 'Only compute report for memory retentions.') do
          @retained_only = true
        end

        HeapProfiler::AbstractResults.top_entries_count = 50
        opts.on("-m", "--max=NUM", Integer, "Max number of entries to output. (Defaults to 50)") do |arg|
          HeapProfiler::AbstractResults.top_entries_count = arg
        end

        help = <<~EOS.lines.join(" ")
          Sets the simdjson parser batch size. It must be larger than the largest JSON document in the heap dump, and defaults to 10MB.
        EOS
        opts.on('--batch-size SIZE', help.strip) do |size_string|
          HeapProfiler::Parser.batch_size = parse_byte_size(size_string)
        rescue ArgumentError => error
          STDERR.puts "Invalid batch-size: #{error.message}"
          exit 1
        end
      end
    end
  end
end
