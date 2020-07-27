# frozen_string_literal: true
require "bundler/gem_tasks"
require "rake/testtask"
require "rake/extensiontask"

Rake::ExtensionTask.new("heap_profiler") do |ext|
  ext.ext_dir = 'ext/heap_profiler'
  ext.lib_dir = "lib/heap_profiler"
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: %i(compile test)
