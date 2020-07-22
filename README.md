# HeapProfiler

TODO: Describe your gem

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

To record a profile:

```ruby
require 'heap-profiler'
HeapProfiler.report('path/to/report/directory') do
  # You code here
end
```

To then analyse the profile

```bash
$ heap-profiler path/to/report/directory
Total allocated: 648.00 B (5 objects)
Total retained: 312.00 B (3 objects)
Total freed: 272.00 B (2 objects)

allocated memory by gem
-----------------------------------
  336.00 B  other
  232.00 B  heap-profiler/lib
   80.00 B  heap-profiler/bin

allocated memory by file
-----------------------------------
  232.00 B  heap-profiler/lib/heap_profiler/reporter.rb
   80.00 B  heap-profiler/bin/generate-report

allocated memory by location
-----------------------------------
  232.00 B  heap-profiler/lib/heap_profiler/reporter.rb:99
   80.00 B  heap-profiler/bin/generate-report:17

allocated memory by class
-----------------------------------
  336.00 B  Hash
  232.00 B  File
   40.00 B  SomeCustomStuff
   40.00 B  Array

allocated objects by gem
-----------------------------------
         2  other
         2  heap-profiler/bin
         1  heap-profiler/lib

allocated objects by file
-----------------------------------
         2  heap-profiler/bin/generate-report
         1  heap-profiler/lib/heap_profiler/reporter.rb

allocated objects by location
-----------------------------------
         2  heap-profiler/bin/generate-report:17
         1  heap-profiler/lib/heap_profiler/reporter.rb:99

allocated objects by class
-----------------------------------
         2  Hash
         1  SomeCustomStuff
         1  File
         1  Array

retained memory by gem
-----------------------------------
  232.00 B  heap-profiler/lib
   80.00 B  heap-profiler/bin

retained memory by file
-----------------------------------
  232.00 B  heap-profiler/lib/heap_profiler/reporter.rb
   80.00 B  heap-profiler/bin/generate-report

retained memory by location
-----------------------------------
  232.00 B  heap-profiler/lib/heap_profiler/reporter.rb:99
   80.00 B  heap-profiler/bin/generate-report:17

retained memory by class
-----------------------------------
  232.00 B  File
   40.00 B  SomeCustomStuff
   40.00 B  Array

retained objects by gem
-----------------------------------
         2  heap-profiler/bin
         1  heap-profiler/lib

retained objects by file
-----------------------------------
         2  heap-profiler/bin/generate-report
         1  heap-profiler/lib/heap_profiler/reporter.rb

retained objects by location
-----------------------------------
         2  heap-profiler/bin/generate-report:17
         1  heap-profiler/lib/heap_profiler/reporter.rb:99

retained objects by class
-----------------------------------
         1  SomeCustomStuff
         1  File
         1  Array

freed memory by gem
-----------------------------------
  232.00 B  heap-profiler/lib
   40.00 B  other

freed memory by file
-----------------------------------
  232.00 B  heap-profiler/lib/heap_profiler/reporter.rb

freed memory by location
-----------------------------------
  232.00 B  heap-profiler/lib/heap_profiler/reporter.rb:99

freed memory by class
-----------------------------------
  232.00 B  File
   40.00 B  Array

freed objects by gem
-----------------------------------
         1  other
         1  heap-profiler/lib

freed objects by file
-----------------------------------
         1  heap-profiler/lib/heap_profiler/reporter.rb

freed objects by location
-----------------------------------
         1  heap-profiler/lib/heap_profiler/reporter.rb:99

freed objects by class
-----------------------------------
         1  File
         1  Array
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/heap-profiler.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
