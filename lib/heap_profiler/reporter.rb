# frozen_string_literal: true

module HeapProfiler
  class << self
    # This works around a Ruby bug present until at least 2.7.1
    # ObjectSpace.dump include module and class names in the dump
    # and for anonymous modules and classes this mean naming them.
    #
    # So we name them at the start of the profile to avoid that.
    #
    # See: https://github.com/ruby/ruby/pull/3349
    if RUBY_VERSION < '2.8'
      def name_anonymous_modules!
        ObjectSpace.each_object(Module) do |mod|
          next if mod.singleton_class?
          next if real_mod_name(mod)
          # We have to assign it at the top level to avoid allocating a string for the name
          ::Object.const_set(:AnonymousClassOrModule, mod)
          ::Object.send(:remove_const, :AnonymousClassOrModule)
        end
      end

      ::Module.alias_method(:__real_mod_name, :name)
      def real_mod_name(mod)
        mod.__real_mod_name
      end
    else
      def name_anonymous_modules!
      end
    end
  end

  class Reporter
    def initialize(dir_path)
      @dir_path = dir_path
      @enable_tracing = !allocation_tracing_enabled?
      @generation = nil
      @partial = true
    end

    def start(partial: true)
      @partial = partial
      FileUtils.mkdir_p(@dir_path)
      ObjectSpace.trace_object_allocations_start if @enable_tracing

      @allocated_heap = open_heap("allocated")
      @retained_heap = open_heap("retained")

      HeapProfiler.name_anonymous_modules!

      GC.start
      GC.disable
      @generation = GC.count
    end

    def stop
      HeapProfiler.name_anonymous_modules!
      ObjectSpace.trace_object_allocations_stop if @enable_tracing

      # we can't use partial dump for allocated.heap, because we need old generations
      # as well to build the classes and strings indexes.
      dump_heap(@allocated_heap)

      GC.enable
      GC.start
      dump_heap(@retained_heap, partial: @partial)
      @allocated_heap.close
      @retained_heap.close
      write_info("generation", @partial ? @generation.to_s : "0")
    end

    def run
      start
      begin
        yield
      rescue Exception
        ObjectSpace.trace_object_allocations_stop if @enable_tracing
        GC.enable
        raise
      else
        stop
      end
    end

    private

    def write_info(key, value)
      File.write(File.join(@dir_path, "#{key}.info"), value)
    end

    if RUBY_VERSION >= '3.0'
      def dump_heap(file, partial: false)
        ObjectSpace.dump_all(output: file, since: partial ? @generation : nil)
        file.close
      end
    else
      # ObjectSpace.dump_all does allocate a few objects in itself (https://bugs.ruby-lang.org/issues/17045)
      # because of this even en empty block of code will report a handful of allocations.
      # To filter them more easily we attribute call `dump_all` from a method with a very specific `file`
      # property.
      class_eval <<~RUBY, '__hprof', __LINE__
        # frozen_string_literal: true
        def dump_heap(file, partial: false)
          ObjectSpace.dump_all(output: file)
          file.close
        end
      RUBY
    end

    def open_heap(name)
      File.open(File.join(@dir_path, "#{name}.heap"), 'w+')
    end

    def allocation_tracing_enabled?
      ObjectSpace.allocation_sourceline(Object.new)
    end
  end
end
