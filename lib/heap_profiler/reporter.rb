# frozen_string_literal: true
module HeapProfiler
  module AnonymousModules
    # This works around a Ruby bug present until at least 2.7.1
    # ObjectSpace.dump include module and class names in the dump
    # and for anonymous modules and classes this mean naming them.
    #
    # So we name them at the start of the profile to avoid that.
    #
    # See: https://github.com/ruby/ruby/pull/3349
    UNBOUND_METHOD_MODULE_NAME = Module.instance_method(:name)
    private_constant :UNBOUND_METHOD_MODULE_NAME

    class << self
      def name_them!
        @count = 0
        ObjectSpace.each_object(Module) do |mod|
          next if mod.singleton_class?
          unless real_mod_name(mod)
            @count += 1
            const_set("A#{@count}", mod)
          end
        end
      end

      def undo!
        while @count > 0
          remove_const("A#{@count}")
          @count -= 1
        end
      end

      if UnboundMethod.method_defined?(:bind_call)
        def real_mod_name(mod)
          UNBOUND_METHOD_MODULE_NAME.bind_call(mod)
        end
      else
        def real_mod_name(mod)
          UNBOUND_METHOD_MODULE_NAME.bind(mod).call
        end
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

      AnonymousModules.name_them!

      4.times { GC.start }
      GC.disable
      dump_heap(@baseline_heap)
    end

    def stop
      ObjectSpace.trace_object_allocations_stop if @enable_tracing
      dump_heap(@allocated_heap)
      GC.enable
      4.times { GC.start }
      dump_heap(@retained_heap)
      @baseline_heap.close
      @allocated_heap.close
      @retained_heap.close
      AnonymousModules.undo!
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
