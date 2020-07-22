# frozen_string_literal: true
module HeapProfiler
  class Reporter
    def initialize(dir_path)
      @dir_path = dir_path
      @enable_tracing = !allocation_tracing_enabled?
    end

    def start
      FileUtils.mkdir_p(@dir_path)
      @baseline_heap = open_heap("baseline")
      @allocated_heap = open_heap("allocated")
      @retained_heap = open_heap("retained")

      4.times { GC.start }
      GC.disable
      dump_heap(@baseline_heap)
      ObjectSpace.trace_object_allocations_start if @enable_tracing
    end

    def stop
      ObjectSpace.trace_object_allocations_stop if @enable_tracing
      dump_heap(@allocated_heap)
      GC.enable
      4.times { GC.start }
      dump_heap(@retained_heap)
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
