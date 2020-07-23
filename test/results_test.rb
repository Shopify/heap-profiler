# frozen_string_literal: true
require "test_helper"

module HeapProfiler
  class ResultsTest < Minitest::Test
    def test_full_results
      results = DiffResults.new(fixtures_path('diffed-heap'), %w(allocated retained))
      io = StringIO.new
      results.pretty_print(io, scale_bytes: true, normalize_paths: true)
      assert_equal <<~EOS, io.string
        Total allocated: 3.97 kB (37 objects)
        Total retained: 392.00 B (9 objects)

        allocated memory by gem
        -----------------------------------
           3.97 kB  other

        allocated memory by file
        -----------------------------------
           3.64 kB  bin/generate-report

        allocated memory by location
        -----------------------------------
           3.17 kB  bin/generate-report:29
          157.00 B  bin/generate-report:23
           72.00 B  bin/generate-report:17
           40.00 B  bin/generate-report:26
           40.00 B  bin/generate-report:25
           40.00 B  bin/generate-report:21
           40.00 B  bin/generate-report:20
           40.00 B  bin/generate-report:19
           40.00 B  bin/generate-report:18

        allocated memory by class
        -----------------------------------
           1.18 kB  Class
          848.00 B  <iseq> (IMEMO)
          597.00 B  String
          528.00 B  Hash
          384.00 B  <ment> (IMEMO)
          192.00 B  Array
           80.00 B  <ifunc> (IMEMO)
           80.00 B  <cref> (IMEMO)
           40.00 B  Symbol
           40.00 B  SomeCustomStuff

        allocated objects by gem
        -----------------------------------
                37  other

        allocated objects by file
        -----------------------------------
                35  bin/generate-report

        allocated objects by location
        -----------------------------------
                27  bin/generate-report:29
                 1  bin/generate-report:26
                 1  bin/generate-report:25
                 1  bin/generate-report:23
                 1  bin/generate-report:21
                 1  bin/generate-report:20
                 1  bin/generate-report:19
                 1  bin/generate-report:18
                 1  bin/generate-report:17

        allocated objects by class
        -----------------------------------
                12  String
                 8  <ment> (IMEMO)
                 4  Array
                 3  Hash
                 2  Class
                 2  <iseq> (IMEMO)
                 2  <ifunc> (IMEMO)
                 2  <cref> (IMEMO)
                 1  Symbol
                 1  SomeCustomStuff

        retained memory by gem
        -----------------------------------
          392.00 B  other

        retained memory by file
        -----------------------------------
          392.00 B  bin/generate-report

        retained memory by location
        -----------------------------------
          160.00 B  bin/generate-report:29
           72.00 B  bin/generate-report:17
           40.00 B  bin/generate-report:21
           40.00 B  bin/generate-report:20
           40.00 B  bin/generate-report:19
           40.00 B  bin/generate-report:18

        retained memory by class
        -----------------------------------
          240.00 B  String
           72.00 B  Array
           40.00 B  Symbol
           40.00 B  SomeCustomStuff

        retained objects by gem
        -----------------------------------
                 9  other

        retained objects by file
        -----------------------------------
                 9  bin/generate-report

        retained objects by location
        -----------------------------------
                 4  bin/generate-report:29
                 1  bin/generate-report:21
                 1  bin/generate-report:20
                 1  bin/generate-report:19
                 1  bin/generate-report:18
                 1  bin/generate-report:17

        retained objects by class
        -----------------------------------
                 6  String
                 1  Symbol
                 1  SomeCustomStuff
                 1  Array

        Allocated String Report
        -----------------------------------
           80.00 B       2  "foo="
                         2  bin/generate-report:29

           80.00 B       2  "foo"
                         2  bin/generate-report:29

           80.00 B       2  "bar="
                         2  bin/generate-report:29

           80.00 B       2  "I am retained"
                         1  bin/generate-report:19
                         1  bin/generate-report:18

           40.00 B       1  "I am retained too"
                         1  bin/generate-report:20

           40.00 B       1  "I am allocated too"
                         1  bin/generate-report:26

           40.00 B       1  "I am allocated"
                         1  bin/generate-report:25

          157.00 B       1  "I am a very very long string I am a very very long string I am a very very long string I am a very very long string "
                         1  bin/generate-report:23


        Retained String Report
        -----------------------------------
           80.00 B       2  "I am retained"
                         1  bin/generate-report:19
                         1  bin/generate-report:18

           40.00 B       1  "foo="
                         1  bin/generate-report:29

           40.00 B       1  "foo"
                         1  bin/generate-report:29

           40.00 B       1  "bar="
                         1  bin/generate-report:29

           40.00 B       1  "I am retained too"
                         1  bin/generate-report:20

      EOS
    end

    private

    def fixtures_path(subpath)
      File.expand_path(File.join('../fixtures', subpath), __FILE__)
    end
  end
end
