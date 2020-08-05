# frozen_string_literal: true
require "test_helper"

module HeapProfiler
  class ResultsTest < Minitest::Test
    def test_full_results
      results = DiffResults.new(fixtures_path('diffed-heap'), %w(allocated retained))
      io = StringIO.new
      results.pretty_print(io, scale_bytes: true, normalize_paths: true)
      assert_equal <<~EOS, io.string
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

      EOS
    end

    private

    def fixtures_path(subpath)
      File.expand_path(File.join('../fixtures', subpath), __FILE__)
    end
  end
end
