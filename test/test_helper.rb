# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "heap_profiler/full"

require 'tempfile'
require 'tmpdir'

require "byebug" unless ENV["CI"]

require "minitest/autorun"
