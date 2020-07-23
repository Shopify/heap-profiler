# frozen_string_literal: true

module HeapProfiler
  REPORT_SOURCE_PATH = __FILE__

  class << self
    # This works around a Ruby bug present until at least 2.7.1
    # ObjectSpace.dump include module and class names in the dump
    # and for anonymous modules and classes this mean naming them.
    #
    # So we name them at the start of the profile to avoid that.
    #
    # See: https://github.com/ruby/ruby/pull/3349
    #
    # TODO: Could we actually do the dump ourselves? objspace is a extension already.
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
    end

    def start
      FileUtils.mkdir_p(@dir_path)
      ObjectSpace.trace_object_allocations_start if @enable_tracing

      @baseline_heap = open_heap("baseline")
      @allocated_heap = open_heap("allocated")
      @retained_heap = open_heap("retained")

      HeapProfiler.name_anonymous_modules!

      4.times { GC.start }
      GC.disable
      dump_heap(@baseline_heap)
    end

    def stop
      HeapProfiler.name_anonymous_modules!
      ObjectSpace.trace_object_allocations_stop if @enable_tracing
      dump_heap(@allocated_heap)
      GC.enable
      4.times { GC.start }
      dump_heap(@retained_heap)
      @baseline_heap.close
      @allocated_heap.close
      @retained_heap.close
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

    def dump_heap(file)
      ObjectSpace.dump_all(output: file)
      file.close
    end

    def open_heap(name)
      File.open(File.join(@dir_path, "#{name}.heap"), 'w+')
    end

    def allocation_tracing_enabled?
      ObjectSpace.allocation_sourceline(Object.new)
    end
  end
end
