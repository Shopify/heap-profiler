# frozen_string_literal: true

require "objspace"
require "fileutils"

require "heap_profiler/version"
require "heap_profiler/reporter"

module HeapProfiler
  Error = Class.new(StandardError)
  CapacityError = Class.new(Error)

  class << self
    attr_accessor :current_reporter

    def start(dir, **kwargs)
      return if current_reporter
      self.current_reporter = Reporter.new(dir)
      current_reporter.start(**kwargs)
    end

    def stop
      current_reporter&.stop
    end

    def report(dir, &block)
      Reporter.new(dir).run(&block)
    end
  end
end
