# frozen_string_literal: true

module HeapProfiler
  class Index
    def initialize(heap)
      @heap = heap
      @classes = {}
      @strings = {}
      @gems = {}
      build!
    end

    def build!
      @classes, @strings = Parser.build_index(@heap.path)
      self
    end

    BUILTIN_CLASSES = {
      FILE: "File",
      ICLASS: "ICLASS",
      COMPLEX: "Complex",
      RATIONAL: "Rational",
      BIGNUM: "Bignum",
      FLOAT: "Float",
      ARRAY: "Array",
      STRING: "String",
      HASH: "Hash",
      SYMBOL: "Symbol",
      MODULE: "Module",
      CLASS: "Class",
      REGEXP: "Regexp",
      MATCH: "MatchData",
      ROOT: "<VM Root>",
      SHAPE: "SHAPE",
    }.freeze

    IMEMO_TYPES = Hash.new { |h, k| h[k] = "<#{k || 'unknown'}> (IMEMO)" }
    DATA_TYPES = Hash.new { |h, k| h[k] = "<#{k || 'unknown'}> (DATA)" }

    def guess_class(object)
      type = object[:type]
      if (class_name = BUILTIN_CLASSES[type])
        return class_name
      end

      return IMEMO_TYPES[object[:imemo_type]] if type == :IMEMO

      class_name = if (class_address = object[:class])
        @classes.fetch(class_address) do
          return DATA_TYPES[object[:struct]] if type == :DATA

          $stderr.puts("WARNING: Couldn't infer class name of: #{object.inspect}")
          nil
        end
      end

      if type == :DATA && (class_name.nil? || class_name == "Object")
        DATA_TYPES[object[:struct]]
      else
        class_name
      end
    end

    def string_value(object)
      value = object[:value]
      return value if value

      if object[:shared]
        @strings[Native.parse_address(object[:references].first)]
      end
    end

    def guess_gem(object)
      path = object[:file]
      @gems[path] ||=
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
  end
end
