# frozen_string_literal: true

module HeapProfiler
  class AbstractResults
    UNIT_PREFIXES = {
      0 => 'B',
      3 => 'kB',
      6 => 'MB',
      9 => 'GB',
      12 => 'TB',
      15 => 'PB',
      18 => 'EB',
      21 => 'ZB',
      24 => 'YB',
    }.freeze

    METRICS = ["memory", "objects", "strings"].freeze
    GROUPINGS = ["gem", "file", "location", "class"].freeze

    attr_reader :types, :dimensions

    def initialize(*, **)
      raise NotImplementedError
    end

    def print_title(io, title)
      io.puts
      io.puts title
      io.puts @colorize.line("-----------------------------------")
    end

    def print_output(io, topic, detail)
      io.puts "#{@colorize.path(topic.to_s.rjust(10))}  #{detail}"
    end

    def print_output2(io, topic1, topic2, detail)
      io.puts "#{@colorize.path(topic1.to_s.rjust(10))}  #{@colorize.path(topic2.to_s.rjust(6))}  #{detail}"
    end

    def normalize_path(path)
      @normalize_path ||= {}
      @normalize_path[path] ||= begin
        if %r!(/gems/.*)*/gems/(?<gemname>[^/]+)(?<rest>.*)! =~ path
          "#{gemname}#{rest}"
        elsif %r!ruby/2\.[^/]+/(?<stdlib>[^/.]+)(?<rest>.*)! =~ path
          "ruby/lib/#{stdlib}#{rest}"
        elsif %r!(?<app>[^/]+/(bin|app|lib))(?<rest>.*)! =~ path
          "#{app}#{rest}"
        else
          path
        end
      end
    end

    def scale_bytes(bytes)
      return "0 B" if bytes.zero?

      scale = Math.log10(bytes).div(3) * 3
      scale = 24 if scale > 24
      format("%.2f #{UNIT_PREFIXES[scale]}", (bytes / 10.0**scale))
    end
  end

  class HeapResults < AbstractResults
    def initialize(heap_path, metrics = METRICS, groupings = GROUPINGS)
      @path = heap_path
      @metrics = metrics
      @groupings = groupings
    end

    def pretty_print(io = $stdout, **options)
      heap = Dump.new(@path)
      index = Index.new(heap)

      color_output = options.fetch(:color_output) { io.respond_to?(:isatty) && io.isatty }
      @colorize = color_output ? Polychrome : Monochrome

      analyzer = Analyzer.new(heap, index)
      dimensions = analyzer.run(@metrics, @groupings)

      io.puts "Total: #{scale_bytes(dimensions['total_memory'].stats)} " \
              "(#{dimensions['total_objects'].stats} objects)"

      @metrics.each do |metric|
        next if metric == "strings"
        @groupings.each do |grouping|
          dump_data(io, dimensions, metric, grouping, options)
        end
      end

      if @metrics.include?("strings")
        dump_strings(io, dimensions, options)
      end
    end

    def dump_data(io, dimensions, metric, grouping, options)
      print_title io, "#{metric} by #{grouping}"
      data = dimensions["#{metric}_by_#{grouping}"].top_n(options.fetch(:top, 50))

      scale_data = metric == "memory" && options[:scale_bytes]
      normalize_paths = options[:normalize_paths]

      if data && !data.empty?
        data.each { |pair| pair[0] = normalize_path(pair[0]) } if normalize_paths
        data.each { |pair| pair[1] = scale_bytes(pair[1]) } if scale_data
        data.each { |k, v| print_output(io, v, k) }
      else
        io.puts "NO DATA"
      end
    end

    def dump_strings(io, dimensions, options)
      normalize_paths = options[:normalize_paths]
      scale_data = options[:scale_bytes]
      top = options.fetch(:top, 50)

      print_title(io, "String Report")

      dimensions["strings"].top_n(top).each do |string|
        memsize = scale_data ? scale_bytes(string.memsize) : string.memsize
        print_output2 io, memsize, string.count, @colorize.string(string.value.inspect)
        string.top_n(top).each do |string_location|
          location = string_location.location
          location = normalize_path(location) if normalize_paths
          print_output2 io, '', string_location.count, location
        end
        io.puts
      end
    end
  end

  class DiffResults < AbstractResults
    TYPES = ["allocated", "retained"].freeze

    def initialize(directory, types = TYPES, metrics = METRICS, groupings = GROUPINGS)
      @directory = directory
      @types = types
      @metrics = metrics
      @groupings = groupings
    end

    def pretty_print(io = $stdout, **options)
      diff = Diff.new(@directory)
      heaps = @types.to_h { |t| [t, diff.public_send("#{t}_diff")] }
      index = Index.new(diff.allocated)

      color_output = options.fetch(:color_output) { io.respond_to?(:isatty) && io.isatty }
      @colorize = color_output ? Polychrome : Monochrome

      dimensions = {}
      heaps.each do |type, heap|
        analyzer = Analyzer.new(heap, index)
        dimensions[type] = analyzer.run(@metrics, @groupings)
      end

      dimensions.each do |type, metrics|
        io.puts "Total #{type}: #{scale_bytes(metrics['total_memory'].stats)} " \
                "(#{metrics['total_objects'].stats} objects)"
      end

      @types.each do |type|
        @metrics.each do |metric|
          next if metric == "strings"
          @groupings.each do |grouping|
            dump_data(io, dimensions, type, metric, grouping, options)
          end
        end
      end

      if @metrics.include?("strings")
        @types.each do |type|
          dump_strings(io, dimensions[type], type, options)
        end
      end
    end

    def dump_data(io, dimensions, type, metric, grouping, options)
      print_title io, "#{type} #{metric} by #{grouping}"
      data = dimensions[type]["#{metric}_by_#{grouping}"].top_n(options.fetch(:top, 50))

      scale_data = metric == "memory" && options[:scale_bytes]
      normalize_paths = options[:normalize_paths]

      if data && !data.empty?
        data.each { |pair| pair[0] = normalize_path(pair[0]) } if normalize_paths
        data.each { |pair| pair[1] = scale_bytes(pair[1]) } if scale_data
        data.each { |k, v| print_output(io, v, k) }
      else
        io.puts "NO DATA"
      end
    end

    def dump_strings(io, dimensions, type, options)
      normalize_paths = options[:normalize_paths]
      scale_data = options[:scale_bytes]
      top = options.fetch(:top, 50)

      print_title(io, "#{type.capitalize} String Report")

      dimensions["strings"].top_n(top).each do |string|
        memsize = scale_data ? scale_bytes(string.memsize) : string.memsize
        print_output2 io, memsize, string.count, @colorize.string(string.value.inspect)
        string.top_n(top).each do |string_location|
          location = string_location.location
          location = normalize_path(location) if normalize_paths
          print_output2 io, '', string_location.count, location
        end
        io.puts
      end
    end
  end
end
