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
      @heap.each_object do |object|
        case object[:type]
        when 'MODULE', 'CLASS'
          @classes[cast_address(object[:address])] = object[:name]
        when 'STRING'
          next if object[:shared]
          if (value = object[:value])
            @strings[cast_address(object[:address])] = value
          end
        end
      end
      self
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

        return @classes.fetch(cast_address(class_address)) do
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
        @strings[cast_address(object[:references].first)]
      end
    end

    def cast_address(address)
      address.to_s.to_i(16)
    end

    def guess_gem(path)
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
