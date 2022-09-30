# HeapProfiler

A memory profiler for Ruby

## Requirements

Ruby(MRI) Version 2.5 and above.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'heap-profiler'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install heap-profiler

## Usage

### Profiling Mode

HeapProfiler can be used to measure memory allocations and retentions of a Ruby code snippet.

To record a profile:

```ruby
require 'heap-profiler'
HeapProfiler.report('path/to/report/directory') do
  # You code here
end
```

To then analyse the profile, run the `heap-profiler` command against the directory you specified.
Note that on large applications this can take a while, but if you are profiling a production
application, you can download the profile directory and do the analysis on another machine.

### Options

```
Usage: heap-profiler <directory_or_heap_dump> OPTIONS

OPTIONS

    -r, --retained-only              Only compute report for memory retentions.
    -m, --max=NUM                    Max number of entries to output. (Defaults to 50)
        --batch-size SIZE            Sets the simdjson parser batch size. It must be larger than the largest JSON document in the heap dump, and defaults to 10MB.
```



```bash
$ heap-profiler path/to/report/directory
      Total allocated: 3.72 kB (36 objects)
      Total retained: 808.00 B (12 objects)

      allocated memory by gem
      -----------------------------------
         3.72 kB  other

      allocated memory by file
      -----------------------------------
         3.72 kB  bin/generate-report

      allocated memory by location
      -----------------------------------
         3.17 kB  bin/generate-report:34
        157.00 B  bin/generate-report:28
         80.00 B  bin/generate-report:21
         72.00 B  bin/generate-report:26
         40.00 B  bin/generate-report:31
         40.00 B  bin/generate-report:30
         40.00 B  bin/generate-report:25
         40.00 B  bin/generate-report:24
         40.00 B  bin/generate-report:23
         40.00 B  bin/generate-report:22

      allocated memory by class
      -----------------------------------
         1.18 kB  Class
        848.00 B  <iseq> (IMEMO)
        597.00 B  String
        384.00 B  <ment> (IMEMO)
        200.00 B  Array
        192.00 B  Hash
         80.00 B  <ifunc> (IMEMO)
         80.00 B  <cref> (IMEMO)
         72.00 B  Date
         40.00 B  Symbol
         40.00 B  SomeCustomStuff

      allocated objects by gem
      -----------------------------------
              36  other

      allocated objects by file
      -----------------------------------
              36  bin/generate-report

      allocated objects by location
      -----------------------------------
              27  bin/generate-report:34
               1  bin/generate-report:31
               1  bin/generate-report:30
               1  bin/generate-report:28
               1  bin/generate-report:26
               1  bin/generate-report:25
               1  bin/generate-report:24
               1  bin/generate-report:23
               1  bin/generate-report:22
               1  bin/generate-report:21

      allocated objects by class
      -----------------------------------
              12  String
               8  <ment> (IMEMO)
               4  Array
               2  Class
               2  <iseq> (IMEMO)
               2  <ifunc> (IMEMO)
               2  <cref> (IMEMO)
               1  Symbol
               1  SomeCustomStuff
               1  Hash
               1  Date

      retained memory by gem
      -----------------------------------
        808.00 B  other

      retained memory by file
      -----------------------------------
        808.00 B  bin/generate-report

      retained memory by location
      -----------------------------------
        168.00 B  bin/generate-report:30
        168.00 B  bin/generate-report:28
        160.00 B  bin/generate-report:34
         80.00 B  bin/generate-report:21
         72.00 B  bin/generate-report:26
         40.00 B  bin/generate-report:25
         40.00 B  bin/generate-report:24
         40.00 B  bin/generate-report:23
         40.00 B  bin/generate-report:22

      retained memory by class
      -----------------------------------
        336.00 B  Hash
        240.00 B  String
         80.00 B  Array
         72.00 B  Date
         40.00 B  Symbol
         40.00 B  SomeCustomStuff

      retained objects by gem
      -----------------------------------
              12  other

      retained objects by file
      -----------------------------------
              12  bin/generate-report

      retained objects by location
      -----------------------------------
               4  bin/generate-report:34
               1  bin/generate-report:30
               1  bin/generate-report:28
               1  bin/generate-report:26
               1  bin/generate-report:25
               1  bin/generate-report:24
               1  bin/generate-report:23
               1  bin/generate-report:22
               1  bin/generate-report:21

      retained objects by class
      -----------------------------------
               6  String
               2  Hash
               1  Symbol
               1  SomeCustomStuff
               1  Date
               1  Array

      Allocated String Report
      -----------------------------------
         80.00 B       2  "foo="
                       2  bin/generate-report:34

         80.00 B       2  "foo"
                       2  bin/generate-report:34

         80.00 B       2  "bar="
                       2  bin/generate-report:34

         80.00 B       2  "I am retained"
                       1  bin/generate-report:23
                       1  bin/generate-report:22

         40.00 B       1  "I am retained too"
                       1  bin/generate-report:24

         40.00 B       1  "I am allocated too"
                       1  bin/generate-report:31

         40.00 B       1  "I am allocated"
                       1  bin/generate-report:30

        157.00 B       1  "I am a very very long string I am a very very long string I am a very very long string I am a very very long string "
                       1  bin/generate-report:28


      Retained String Report
      -----------------------------------
         80.00 B       2  "I am retained"
                       1  bin/generate-report:23
                       1  bin/generate-report:22

         40.00 B       1  "foo="
                       1  bin/generate-report:34

         40.00 B       1  "foo"
                       1  bin/generate-report:34

         40.00 B       1  "bar="
                       1  bin/generate-report:34

         40.00 B       1  "I am retained too"
                       1  bin/generate-report:24
```

### Heap Analysis

Alternatively if you with to analyse the entire heap of your Ruby process.

If you can, you should enable allocation tracing as early as possible during your application boot process, e.g. in `config/boot.rb` for Rails apps.

```ruby
require 'objspace'
ObjectSpace.trace_object_allocations_start
```

Then to dump the heap:

```ruby
require 'objspace'
ObjectSpace.dump_all(output: File.open('path/to/file.heap', 'w+'))
```

Then run `heap-profiler` against it:

```bash
heap-profiler path/to/file.heap
```

## How is it different from memory_profiler?

`heap-profiler` is heavilly inspired of `memory_profiler`, it aims at being as similar as possible.
However it uses a different Ruby API to gather data.

`memory_profiler` uses [`ObjectSpace.each_object`](https://ruby-doc.org/core-2.7.1/ObjectSpace.html#method-c-each_object) which contrary to what its name
suggest doesn't expose all existing object. There are many objects that the Ruby VM consider "internal" (see MRI's `internal_object_p(VALUE)`) and won't yield to `each_object`.

On the other hand `heap-profiler` uses [`ObjectSpace.dump_all`](https://ruby-doc.org/stdlib-2.7.1/libdoc/objspace/rdoc/ObjectSpace.html#method-c-dump_all), which
does serialize every objects, including internal ones, into JSON files. This leads to more exhaustive reports.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/heap-profiler.

## Thanks

This gem was heavilly inspired from http://github.com/SamSaffron/memory_profiler, it even borrowed some code from it, so thanks to [@SamSaffron](https://github.com/SamSaffron).

It also makes heavy use of https://github.com/simdjson/simdjson for fast heap dump parsing. So big thanks to [Daniel Lemire](https://github.com/lemire) and [John Keiser](https://github.com/jkeiser).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
