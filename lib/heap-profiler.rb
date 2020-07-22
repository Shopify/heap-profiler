# frozen_string_literal: true

# This file is the gem entrypoint loaded by bundler.
# We only load what's needed to take heap dumps,
# not the code required to analyse them.
require "heap_profiler/runtime"
