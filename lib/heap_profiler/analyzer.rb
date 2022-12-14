# frozen_string_literal: true

module HeapProfiler
  class Analyzer
    class Dimension
      attr_reader :objects, :memory
      def initialize
        @objects = 0
        @memory = 0
      end

      def process(_index, object)
        @objects += 1
        @memory += object[:memsize]
      end

      def stats(metric)
        case metric
        when "objects"
          objects
        when "memory"
          memory
        else
          raise "Invalid metric: #{metric.inspect}"
        end
      end
    end

    class GroupedDimension < Dimension
      class << self
        def build(grouping)
          klass = case grouping
          when "file"
            FileGroupDimension
          when "location"
            LocationGroupDimension
          when "gem"
            GemGroupDimension
          when "class"
            ClassGroupDimension
          else
            raise "Unknown grouping key: #{grouping.inspect}"
          end
          klass.new
        end
      end

      def initialize
        @objects = Hash.new { |h, k| h[k] = 0 }
        @memory = Hash.new { |h, k| h[k] = 0 }
      end

      def process(index, object)
        if (group = @grouping.call(index, object))
          @objects[group] += 1
          @memory[group] += object[:memsize]
        end
      end

      def top_n(metric, max)
        values = stats(metric).sort do |a, b|
          b[1] <=> a[1]
        end
        top = values.take(max)
        top.sort! do |a, b|
          cmp = b[1] <=> a[1]
          cmp == 0 ? b[0] <=> a[0] : cmp
        end
        top
      end
    end

    class FileGroupDimension < GroupedDimension
      def process(_index, object)
        if (group = object[:file])
          @objects[group] += 1
          @memory[group] += object[:memsize]
        end
      end
    end

    class LocationGroupDimension < GroupedDimension
      def process(_index, object)
        file = object[:file]
        line = object[:line]

        if file && line
          group = "#{file}:#{line}"
          @objects[group] += 1
          @memory[group] += object[:memsize]
        end
      end
    end

    class GemGroupDimension < GroupedDimension
      def process(index, object)
        if (group = index.guess_gem(object))
          @objects[group] += 1
          @memory[group] += object[:memsize]
        end
      end
    end

    class ClassGroupDimension < GroupedDimension
      def process(index, object)
        if (group = index.guess_class(object))
          @objects[group] += 1
          @memory[group] += object[:memsize]
        end
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

        def top_n(max)
          values = @locations_counts.values
          values.sort! do |a, b|
            cmp = b.count <=> a.count
            cmp == 0 ? b.location <=> a.location : cmp
          end
          values.take(max)
        end
      end

      attr_reader :stats
      def initialize
        @stats = Hash.new { |h, k| h[k] = StringGroup.new(k) }
      end

      def process(_index, object)
        return unless object[:type] == :STRING
        value = object[:value]
        return unless value # broken strings etc
        @stats[value].process(object)
      end

      def top_n(max)
        values = @stats.values
        values.sort! do |a, b|
          b.count <=> a.count
        end
        top = values.take(max)
        top.sort! do |a, b|
          cmp = b.count <=> a.count
          cmp == 0 ? b.value <=> a.value : cmp
        end
        top
      end
    end

    class ShapeEdgeDimension
      def initialize
        @stats = Hash.new(0)
      end

      def process(_index, object)
        if name = object[:edge_name]
          @stats[name] += 1
        end
      end

      def top_n(max)
        @stats.sort do |(a_name, a_count), (b_name, b_count)|
          cmp = b_count <=> a_count
          if cmp == 0
            a_name <=> b_name
          else
            cmp
          end
        end.take(max)
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
        elsif metric == "shape_edges"
          dimensions["shape_edges"] = ShapeEdgeDimension.new
        else
          dimensions["total"] = Dimension.new
          groupings.each do |grouping|
            dimensions[grouping] = GroupedDimension.build(grouping)
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
