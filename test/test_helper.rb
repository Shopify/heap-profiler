# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "heap_profiler/full"

if GC.respond_to?(:verify_compaction_references)
  GC.verify_compaction_references(double_heap: true, toward: :empty)
end

require "tempfile"
require "tmpdir"
require "stringio"

require "byebug" unless ENV["CI"]

require "minitest/autorun"
