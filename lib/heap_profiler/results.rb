# frozen_string_literal: true

module HeapProfiler
  class Results
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

    TYPES = ["allocated", "retained", "freed"].freeze
    METRICS = ["memory", "objects", "strings"].freeze
    GROUPINGS = ["gem", "file", "location", "class"].freeze

    attr_reader :analyzer, :types, :dimensions

    def initialize(analyzer, types = TYPES, metrics = METRICS, groupings = GROUPINGS)
      @analyzer = analyzer
      @types = types
      @metrics = metrics
      @groupings = groupings
    end

    def pretty_print(io = $stdout, **options)
      color_output = options.fetch(:color_output) { io.respond_to?(:isatty) && io.isatty }
      @colorize = color_output ? Polychrome : Monochrome

      dimensions = {}
      @types.each do |type|
        dimensions[type] = analyzer.run(type, @metrics, @groupings)
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
        print_output2 io, scale_data ? scale_bytes(string.memsize) : string.memsize, string.count, string.value.inspect
        string.top_n(top).each do |string_location|
          location = string_location.location
          location = normalize_path(location) if normalize_paths
          print_output2 io, '', string_location.count, location
        end
        io.puts
      end
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
end
