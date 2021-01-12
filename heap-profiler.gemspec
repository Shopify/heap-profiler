# frozen_string_literal: true
require_relative 'lib/heap_profiler/version'

Gem::Specification.new do |spec|
  spec.name          = "heap-profiler"
  spec.version       = HeapProfiler::VERSION
  spec.authors       = ["Jean Boussier"]
  spec.email         = ["jean.boussier@gmail.com"]

  spec.summary       = 'Ruby heap profiling tool'
  spec.description   = 'Make several heap dumps and summarize allocated, retained memory'
  spec.homepage      = "https://github.com/Shopify/heap-profiler"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org/"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    %x(git ls-files -z).split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.extensions << "ext/heap_profiler/extconf.rb"
end
