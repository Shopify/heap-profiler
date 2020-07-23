# frozen_string_literal: true

module HeapProfiler
  class Analyzer
    class Dimension
      METRICS = {
        "objects" => -> (_object) { 1 },
        "memory" => -> (object) { object[:memsize].to_i },
      }.freeze

      attr_reader :stats
      def initialize(metric)
        @stats = 0
        @metric = METRICS.fetch(metric)
      end

      def process(_analyzer, object)
        @stats += @metric.call(object)
      end

      def sort!
      end
    end

    class GroupedDimension < Dimension
      GROUPINGS = {
        "file" => -> (_analizer, object) { object[:file] },
        "location" => -> (_analizer, object) do
          if (file = object[:file]) && (line = object[:line])
            "#{file}:#{line}"
          end
        end,
        "gem" => -> (analyzer, object) { analyzer.guess_gem(object[:file]) },
        "class" => -> (analyzer, object) { analyzer.guess_class(object) },
      }.freeze

      attr_reader :stats
      def initialize(metric, grouping)
        super(metric)
        @grouping = GROUPINGS.fetch(grouping)
        @stats = Hash.new { |h, k| h[k] = 0 }
      end

      def process(analyzer, object)
        if (group = @grouping.call(analyzer, object))
          @stats[group] += @metric.call(object)
        end
      end

      def top_n(max)
        stats.sort do |a, b|
          cmp = b[1] <=> a[1]
          cmp == 0 ? b[0] <=> a[0] : cmp
        end.take(max)
      end
    end

    class StringDimension
      class StringLocation
        attr_reader :location, :count, :memsize

        def initialize(location)
          @location = location
          @count = 0
          @memsize = 0
        end

        def process(object)
          @count += 1
          @memsize += object[:memsize]
        end
      end

      class StringGroup
        attr_reader :value, :count, :memsize, :locations
        def initialize(value) # TODO: should we consider encoding?
          @value = value
          @locations_counts = Hash.new { |h, k| h[k] = StringLocation.new(k) }
          @count = 0
          @memsize = 0
        end

        def process(object)
          @count += 1
          @memsize += object[:memsize]
          if (file = object[:file]) && (line = object[:line])
            @locations_counts["#{file}:#{line}"].process(object)
          end
        end

        def top_n(_max)
          values = @locations_counts.values
          values.sort! do |a, b|
            cmp = b.count <=> a.count
            cmp == 0 ? b.location <=> a.location : cmp
          end
        end
      end

      attr_reader :stats
      def initialize
        @stats = Hash.new { |h, k| h[k] = StringGroup.new(k) }
      end

      def process(_analyzer, object)
        return unless object[:type] == "STRING"
        value = object[:value]
        return unless value # broken strings etc
        @stats[value].process(object)
      end

      def top_n(max)
        values = @stats.values
        values.sort! do |a, b|
          cmp = b.count <=> a.count
          cmp == 0 ? b.value <=> a.value : cmp
        end
        values.take(max)
      end
    end

    # Dumping the heap does allocates by itself
    # TODO: See with Aaron and Allan what they are and how to get rid of them
    # These two hashes are referenced by `"root":"machine_context"`. However `0x7fb0a5bcfc20` isn't in the dump.
    # {"address":"0x7fb0a280e5a8", "type":"HASH", "size":1, "references":["0x7fb0a5bcfc20"], "memsize":168}
    # {"address":"0x7fb0a280e9e0", "type":"HASH", "size":1, "references":["0x7fb0a5bcfc20"], "memsize":168}
    # No idea where that file come from.
    # {"address":"0x7fb0a5bcfdb0", "type":"FILE", "fd":-1, "references":["0x7fb0a5bcfd88"], "memsize":232}
    SIDE_EFFECT_ALLOCATIONS = 3
    SIDE_EFFECT_ALLOCATIONS_MEMSIZE = 168 * 2 + 232
    SIDE_EFFECT_RETENTIONS = 1
    SIDE_EFFECT_RETENTIONS_MEMSIZE = 232
    SIDE_EFFECT_RELEASES = 2
    SIDE_EFFECT_RELEASES_MEMSIZE = 168 * 2

    def initialize(report_directory)
      @report_directory = report_directory
      @baseline = open_dump('baseline')
      @allocated = open_dump('allocated')
      @retained = open_dump('retained')
      @gem_guess_cache = {}
    end

    def run(type, metrics, groupings)
      dimensions = {}
      metrics.each do |metric|
        if metric == "strings"
          dimensions["strings"] = StringDimension.new
        else
          dimensions["total_#{metric}"] = Dimension.new(metric)
          groupings.each do |grouping|
            dimensions["#{metric}_by_#{grouping}"] = GroupedDimension.new(metric, grouping)
          end
        end
      end

      heap_diff = public_send(type)
      processors = dimensions.values
      heap_diff.each_object do |object|
        processors.each { |p| p.process(self, object) }
      end
      dimensions
    end

    BUILTIN_CLASSES = {
      "FILE" => "File",
      "ICLASS" => "ICLASS",
      "COMPLEX" => "Complex",
      "RATIONAL" => "Rational",
      "BIGNUM" => "Bignum",
      "FLOAT" => "Float",
      "ARRAY" => "Array",
      "STRING" => "String",
      "HASH" => "Hash",
      "SYMBOL" => "Symbol",
      "MODULE" => "Module",
      "CLASS" => "Class",
      "REGEXP" => "Regexp",
      "MATCH" => "MatchData",
      "ROOT" => "<VM Root>",
    }.freeze

    IMEMO_TYPES = Hash.new { |h, k| h[k] = "<#{k}> (IMEMO)" }
    DATA_TYPES = Hash.new { |h, k| h[k] = "#{k.capitalize} (DATA)" }

    def guess_class(object)
      type = object[:type]
      if (class_name = BUILTIN_CLASSES[type])
        return class_name
      end

      return IMEMO_TYPES[object[:imemo_type]] if type == 'IMEMO'
      return DATA_TYPES[object[:struct]] if type == 'DATA'

      if type == "OBJECT" || type == "STRUCT"
        class_address = object[:class]
        return unless class_address

        return class_index.fetch(object_address(class_address)) do
          $stderr.puts("WARNING: Couldn't infer class name of: #{object.inspect}")
          nil
        end
      end

      raise "[BUG] Couldn't infer type of #{object.inspect}"
    end

    def string_value(object)
      value = object[:value]
      return value if value

      if object[:shared]
        string_index[object_address(object[:references].first)]
      end
    end

    def string_index
      @string_index ||= begin
        build_indices
        @string_index
      end
    end

    def class_index
      @class_index ||= begin
        build_indices
        @class_index
      end
    end

    def object_address(address)
      address.to_s.to_i(16)
    end

    def build_indices
      @string_index = {}
      @class_index = {}
      @allocated.each_object do |object|
        case object[:type]
        when 'MODULE', 'CLASS'
          @class_index[object_address(object[:address])] = object[:name]
        when 'STRING'
          next if object[:shared]
          if (value = object[:value])
            @string_index[object_address(object[:address])] = value
          end
        end
      end
    end

    def guess_gem(path)
      @gem_guess_cache[path] ||=
        if %r{(/gems/.*)*/gems/(?<gemname>[^/]+)} =~ path
          gemname
        elsif %r{/rubygems[\./]}.match?(path)
          "rubygems"
        elsif %r{ruby/2\.[^/]+/(?<stdlib>[^/\.]+)} =~ path
          stdlib
        elsif %r{(?<app>[^/]+/(bin|app|lib))} =~ path
          app
        else
          "other"
        end
    end

    def total_allocated
      allocated.stats.count - SIDE_EFFECT_ALLOCATIONS
    end

    def total_allocated_memsize
      allocated.stats.memsize - SIDE_EFFECT_ALLOCATIONS_MEMSIZE
    end

    def total_retained
      retained.stats.count - SIDE_EFFECT_RETENTIONS
    end

    def total_retained_memsize
      retained.stats.memsize - SIDE_EFFECT_RETENTIONS_MEMSIZE
    end

    def total_freed
      freed.stats.count - SIDE_EFFECT_RELEASES
    end

    def total_freed_memsize
      freed.stats.memsize - SIDE_EFFECT_RELEASES_MEMSIZE
    end

    def allocated
      @allocated_diff ||= build_diff('allocated-diff', @baseline, @allocated)
    end

    def retained
      @retained_diff ||= build_diff('retained-diff', @baseline, @retained)
    end

    def freed
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
