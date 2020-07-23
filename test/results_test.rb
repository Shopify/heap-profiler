# frozen_string_literal: true
require "test_helper"

module HeapProfiler
  class ResultsTest < Minitest::Test
    def test_full_results
      Dir.mktmpdir do |dir|
        assert_equal true, system(File.expand_path('../../bin/generate-report', __FILE__), dir)

        results = Results.new(Analyzer.new(dir))
        io = StringIO.new
        results.pretty_print(io, scale_bytes: true, normalize_paths: true)
        assert_equal <<~EOS, io.string
          Total allocated: 1.04 kB (11 objects)
          Total retained: 464.00 B (6 objects)
          Total freed: 352.00 B (4 objects)

          allocated memory by gem
          -----------------------------------
            469.00 B  heap-profiler/bin
            336.00 B  other
            232.00 B  heap-profiler/lib

          allocated memory by file
          -----------------------------------
            469.00 B  heap-profiler/bin/generate-report
            232.00 B  heap-profiler/lib/heap_profiler/reporter.rb

          allocated memory by location
          -----------------------------------
            232.00 B  heap-profiler/lib/heap_profiler/reporter.rb:99
            157.00 B  heap-profiler/bin/generate-report:23
             72.00 B  heap-profiler/bin/generate-report:17
             40.00 B  heap-profiler/bin/generate-report:26
             40.00 B  heap-profiler/bin/generate-report:25
             40.00 B  heap-profiler/bin/generate-report:21
             40.00 B  heap-profiler/bin/generate-report:20
             40.00 B  heap-profiler/bin/generate-report:19
             40.00 B  heap-profiler/bin/generate-report:18

          allocated memory by class
          -----------------------------------
            357.00 B  String
            336.00 B  Hash
            232.00 B  File
             72.00 B  Array
             40.00 B  SomeCustomStuff

          allocated objects by gem
          -----------------------------------
                   8  heap-profiler/bin
                   2  other
                   1  heap-profiler/lib

          allocated objects by file
          -----------------------------------
                   8  heap-profiler/bin/generate-report
                   1  heap-profiler/lib/heap_profiler/reporter.rb

          allocated objects by location
          -----------------------------------
                   1  heap-profiler/lib/heap_profiler/reporter.rb:99
                   1  heap-profiler/bin/generate-report:26
                   1  heap-profiler/bin/generate-report:25
                   1  heap-profiler/bin/generate-report:23
                   1  heap-profiler/bin/generate-report:21
                   1  heap-profiler/bin/generate-report:20
                   1  heap-profiler/bin/generate-report:19
                   1  heap-profiler/bin/generate-report:18
                   1  heap-profiler/bin/generate-report:17

          allocated objects by class
          -----------------------------------
                   6  String
                   2  Hash
                   1  SomeCustomStuff
                   1  File
                   1  Array

          retained memory by gem
          -----------------------------------
            232.00 B  heap-profiler/lib
            232.00 B  heap-profiler/bin

          retained memory by file
          -----------------------------------
            232.00 B  heap-profiler/lib/heap_profiler/reporter.rb
            232.00 B  heap-profiler/bin/generate-report

          retained memory by location
          -----------------------------------
            232.00 B  heap-profiler/lib/heap_profiler/reporter.rb:99
             72.00 B  heap-profiler/bin/generate-report:17
             40.00 B  heap-profiler/bin/generate-report:21
             40.00 B  heap-profiler/bin/generate-report:20
             40.00 B  heap-profiler/bin/generate-report:19
             40.00 B  heap-profiler/bin/generate-report:18

          retained memory by class
          -----------------------------------
            232.00 B  File
            120.00 B  String
             72.00 B  Array
             40.00 B  SomeCustomStuff

          retained objects by gem
          -----------------------------------
                   5  heap-profiler/bin
                   1  heap-profiler/lib

          retained objects by file
          -----------------------------------
                   5  heap-profiler/bin/generate-report
                   1  heap-profiler/lib/heap_profiler/reporter.rb

          retained objects by location
          -----------------------------------
                   1  heap-profiler/lib/heap_profiler/reporter.rb:99
                   1  heap-profiler/bin/generate-report:21
                   1  heap-profiler/bin/generate-report:20
                   1  heap-profiler/bin/generate-report:19
                   1  heap-profiler/bin/generate-report:18
                   1  heap-profiler/bin/generate-report:17

          retained objects by class
          -----------------------------------
                   3  String
                   1  SomeCustomStuff
                   1  File
                   1  Array

          freed memory by gem
          -----------------------------------
            232.00 B  heap-profiler/lib
            120.00 B  other

          freed memory by file
          -----------------------------------
            232.00 B  heap-profiler/lib/heap_profiler/reporter.rb

          freed memory by location
          -----------------------------------
            232.00 B  heap-profiler/lib/heap_profiler/reporter.rb:99

          freed memory by class
          -----------------------------------
            232.00 B  File
             80.00 B  String
             40.00 B  Array

          freed objects by gem
          -----------------------------------
                   3  other
                   1  heap-profiler/lib

          freed objects by file
          -----------------------------------
                   1  heap-profiler/lib/heap_profiler/reporter.rb

          freed objects by location
          -----------------------------------
                   1  heap-profiler/lib/heap_profiler/reporter.rb:99

          freed objects by class
          -----------------------------------
                   2  String
                   1  File
                   1  Array

          Allocated String Report
          -----------------------------------
             80.00 B       2  "I am retained"
                           1  heap-profiler/bin/generate-report:19
                           1  heap-profiler/bin/generate-report:18

             40.00 B       1  "I am retained too"
                           1  heap-profiler/bin/generate-report:20

             40.00 B       1  "I am allocated too"
                           1  heap-profiler/bin/generate-report:26

             40.00 B       1  "I am allocated"
                           1  heap-profiler/bin/generate-report:25

            157.00 B       1  "I am a very very long string I am a very very long string I am a very very long string I am a very very long string "
                           1  heap-profiler/bin/generate-report:23


          Retained String Report
          -----------------------------------
             80.00 B       2  "I am retained"
                           1  heap-profiler/bin/generate-report:19
                           1  heap-profiler/bin/generate-report:18

             40.00 B       1  "I am retained too"
                           1  heap-profiler/bin/generate-report:20


          Freed String Report
          -----------------------------------
             40.00 B       1  "i am free too"

             40.00 B       1  "i am free"

        EOS
      end
    end
  end
end
