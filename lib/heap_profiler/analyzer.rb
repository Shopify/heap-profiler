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

      def process(_index, object)
        @stats += @metric.call(object)
      end

      def sort!
      end
    end

    class GroupedDimension < Dimension
      GROUPINGS = {
        "file" => -> (_index, object) { object[:file] },
        "location" => -> (_index, object) do
          if (file = object[:file]) && (line = object[:line])
            "#{file}:#{line}"
          end
        end,
        "gem" => -> (index, object) { index.guess_gem(object[:file]) },
        "class" => -> (index, object) { index.guess_class(object) },
      }.freeze

      attr_reader :stats
      def initialize(metric, grouping)
        super(metric)
        @grouping = GROUPINGS.fetch(grouping)
        @stats = Hash.new { |h, k| h[k] = 0 }
      end

      def process(index, object)
        if (group = @grouping.call(index, object))
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

      def process(_index, object)
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

    def initialize(heap, index)
      @heap = heap
      @index = index
    end

    def run(metrics, groupings)
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

      processors = dimensions.values
      @heap.each_object do |object|
        processors.each { |p| p.process(@index, object) }
      end
      dimensions
    end
  end
end
