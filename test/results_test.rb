# frozen_string_literal: true
require "test_helper"

module HeapProfiler
  class ResultsTest < Minitest::Test
    def test_diff_results
      results = DiffResults.new(fixtures_path('diffed-heap'), %w(allocated retained))
      io = StringIO.new
      results.pretty_print(io, scale_bytes: true, normalize_paths: true)
      assert_equal <<~EOS, io.string
        Total allocated: 3.10 kB (46 objects)
        Total retained: 1.26 kB (28 objects)

        allocated memory by gem
        -----------------------------------
           2.78 kB  other
          320.00 B  heap-profiler/lib

        allocated memory by file
        -----------------------------------
           2.78 kB  bin/generate-report
          320.00 B  heap-profiler/lib/heap_profiler/reporter.rb

        allocated memory by location
        -----------------------------------
           1.70 kB  bin/generate-report:47
          200.00 B  bin/generate-report:41
          200.00 B  bin/generate-report:32
          120.00 B  bin/generate-report:34
          112.00 B  bin/generate-report:39
           80.00 B  bin/generate-report:44
           80.00 B  bin/generate-report:38
           80.00 B  bin/generate-report:37
           80.00 B  bin/generate-report:33
           80.00 B  heap-profiler/lib/heap_profiler/reporter.rb:56
           80.00 B  heap-profiler/lib/heap_profiler/reporter.rb:51
           80.00 B  heap-profiler/lib/heap_profiler/reporter.rb:50
           40.00 B  bin/generate-report:43
           40.00 B  bin/generate-report:36
           40.00 B  bin/generate-report:35
           40.00 B  heap-profiler/lib/heap_profiler/reporter.rb:72
           40.00 B  heap-profiler/lib/heap_profiler/reporter.rb:55

        allocated memory by class
        -----------------------------------
          840.00 B  Class
          520.00 B  String
          440.00 B  <callcache> (IMEMO)
          432.00 B  <ment> (IMEMO)
          360.00 B  <constcache> (IMEMO)
          192.00 B  Hash
          120.00 B  SomeCustomStuff
          120.00 B  Array
           72.00 B  Date

        allocated objects by gem
        -----------------------------------
                38  other
                 8  heap-profiler/lib

        allocated objects by file
        -----------------------------------
                38  bin/generate-report
                 8  heap-profiler/lib/heap_profiler/reporter.rb

        allocated objects by location
        -----------------------------------
                18  bin/generate-report:47
                 5  bin/generate-report:32
                 2  bin/generate-report:41
                 2  bin/generate-report:39
                 2  bin/generate-report:38
                 2  bin/generate-report:34
                 2  bin/generate-report:33
                 2  heap-profiler/lib/heap_profiler/reporter.rb:56
                 2  heap-profiler/lib/heap_profiler/reporter.rb:51
                 2  heap-profiler/lib/heap_profiler/reporter.rb:50
                 1  bin/generate-report:44
                 1  bin/generate-report:43
                 1  bin/generate-report:37
                 1  bin/generate-report:36
                 1  bin/generate-report:35
                 1  heap-profiler/lib/heap_profiler/reporter.rb:72
                 1  heap-profiler/lib/heap_profiler/reporter.rb:55

        allocated objects by class
        -----------------------------------
                11  <callcache> (IMEMO)
                 9  <ment> (IMEMO)
                 9  <constcache> (IMEMO)
                 8  String
                 3  SomeCustomStuff
                 2  Class
                 2  Array
                 1  Hash
                 1  Date

        retained memory by gem
        -----------------------------------
          944.00 B  other
          320.00 B  heap-profiler/lib

        retained memory by file
        -----------------------------------
          944.00 B  bin/generate-report
          320.00 B  heap-profiler/lib/heap_profiler/reporter.rb

        retained memory by location
        -----------------------------------
          232.00 B  bin/generate-report:47
          160.00 B  bin/generate-report:32
          120.00 B  bin/generate-report:34
          112.00 B  bin/generate-report:39
           80.00 B  bin/generate-report:38
           80.00 B  bin/generate-report:37
           80.00 B  heap-profiler/lib/heap_profiler/reporter.rb:56
           80.00 B  heap-profiler/lib/heap_profiler/reporter.rb:51
           80.00 B  heap-profiler/lib/heap_profiler/reporter.rb:50
           40.00 B  bin/generate-report:41
           40.00 B  bin/generate-report:36
           40.00 B  bin/generate-report:35
           40.00 B  bin/generate-report:33
           40.00 B  heap-profiler/lib/heap_profiler/reporter.rb:72
           40.00 B  heap-profiler/lib/heap_profiler/reporter.rb:55

        retained memory by class
        -----------------------------------
          400.00 B  <callcache> (IMEMO)
          360.00 B  <constcache> (IMEMO)
          240.00 B  String
           80.00 B  Array
           72.00 B  Thread::Mutex
           72.00 B  Date
           40.00 B  SomeCustomStuff

        retained objects by gem
        -----------------------------------
                20  other
                 8  heap-profiler/lib

        retained objects by file
        -----------------------------------
                20  bin/generate-report
                 8  heap-profiler/lib/heap_profiler/reporter.rb

        retained objects by location
        -----------------------------------
                 5  bin/generate-report:47
                 4  bin/generate-report:32
                 2  bin/generate-report:39
                 2  bin/generate-report:38
                 2  bin/generate-report:34
                 2  heap-profiler/lib/heap_profiler/reporter.rb:56
                 2  heap-profiler/lib/heap_profiler/reporter.rb:51
                 2  heap-profiler/lib/heap_profiler/reporter.rb:50
                 1  bin/generate-report:41
                 1  bin/generate-report:37
                 1  bin/generate-report:36
                 1  bin/generate-report:35
                 1  bin/generate-report:33
                 1  heap-profiler/lib/heap_profiler/reporter.rb:72
                 1  heap-profiler/lib/heap_profiler/reporter.rb:55

        retained objects by class
        -----------------------------------
                10  <callcache> (IMEMO)
                 9  <constcache> (IMEMO)
                 5  String
                 1  Thread::Mutex
                 1  SomeCustomStuff
                 1  Date
                 1  Array

        Allocated String Report
        -----------------------------------
           80.00 B       2  "I am retained"
                         1  bin/generate-report:36
                         1  bin/generate-report:35

           40.00 B       1  "foo="
                         1  bin/generate-report:47

           40.00 B       1  "bar="
                         1  bin/generate-report:47

           80.00 B       1  "I am retained too"
                         1  bin/generate-report:37

           80.00 B       1  "I am allocated too"
                         1  bin/generate-report:44

           40.00 B       1  "I am allocated"
                         1  bin/generate-report:43

          160.00 B       1  "I am a very very long string I am a very very long string I am a very very long string I am a very very long string "
                         1  bin/generate-report:41


        Retained String Report
        -----------------------------------
           80.00 B       2  "I am retained"
                         1  bin/generate-report:36
                         1  bin/generate-report:35

           40.00 B       1  "foo="
                         1  bin/generate-report:47

           40.00 B       1  "bar="
                         1  bin/generate-report:47

           80.00 B       1  "I am retained too"
                         1  bin/generate-report:37

      EOS
    end

    def test_heap_results
      results = HeapResults.new(fixtures_path('diffed-heap/retained.heap'))
      io = StringIO.new
      results.pretty_print(io, scale_bytes: true, normalize_paths: true)
      assert_equal <<~EOS, io.string
        Total: 54.30 kB (516 objects)

        memory by gem
        -----------------------------------
          53.98 kB  other
          320.00 B  heap-profiler/lib

        memory by file
        -----------------------------------
          944.00 B  bin/generate-report
          320.00 B  heap-profiler/lib/heap_profiler/reporter.rb

        memory by location
        -----------------------------------
          232.00 B  bin/generate-report:47
          160.00 B  bin/generate-report:32
          120.00 B  bin/generate-report:34
          112.00 B  bin/generate-report:39
           80.00 B  bin/generate-report:38
           80.00 B  bin/generate-report:37
           80.00 B  heap-profiler/lib/heap_profiler/reporter.rb:56
           80.00 B  heap-profiler/lib/heap_profiler/reporter.rb:51
           80.00 B  heap-profiler/lib/heap_profiler/reporter.rb:50
           40.00 B  bin/generate-report:41
           40.00 B  bin/generate-report:36
           40.00 B  bin/generate-report:35
           40.00 B  bin/generate-report:33
           40.00 B  heap-profiler/lib/heap_profiler/reporter.rb:72
           40.00 B  heap-profiler/lib/heap_profiler/reporter.rb:55

        memory by class
        -----------------------------------
          53.03 kB  SHAPE
          400.00 B  <callcache> (IMEMO)
          360.00 B  <constcache> (IMEMO)
          240.00 B  String
           80.00 B  Array
           72.00 B  <mutex> (DATA)
           72.00 B  <Date> (DATA)

        objects by gem
        -----------------------------------
               508  other
                 8  heap-profiler/lib

        objects by file
        -----------------------------------
                20  bin/generate-report
                 8  heap-profiler/lib/heap_profiler/reporter.rb

        objects by location
        -----------------------------------
                 5  bin/generate-report:47
                 4  bin/generate-report:32
                 2  bin/generate-report:39
                 2  bin/generate-report:38
                 2  bin/generate-report:34
                 2  heap-profiler/lib/heap_profiler/reporter.rb:56
                 2  heap-profiler/lib/heap_profiler/reporter.rb:51
                 2  heap-profiler/lib/heap_profiler/reporter.rb:50
                 1  bin/generate-report:41
                 1  bin/generate-report:37
                 1  bin/generate-report:36
                 1  bin/generate-report:35
                 1  bin/generate-report:33
                 1  heap-profiler/lib/heap_profiler/reporter.rb:72
                 1  heap-profiler/lib/heap_profiler/reporter.rb:55

        objects by class
        -----------------------------------
               488  SHAPE
                10  <callcache> (IMEMO)
                 9  <constcache> (IMEMO)
                 5  String
                 1  Array
                 1  <mutex> (DATA)
                 1  <Date> (DATA)

        String Report
        -----------------------------------
           80.00 B       2  \"I am retained\"
                         1  bin/generate-report:36
                         1  bin/generate-report:35

           40.00 B       1  \"foo=\"
                         1  bin/generate-report:47

           40.00 B       1  \"bar=\"
                         1  bin/generate-report:47

           80.00 B       1  \"I am retained too\"
                         1  bin/generate-report:37


        Shape Edges Report
        -----------------------------------
                 7  @dependencies
                 7  @name
                 7  @path
                 7  @version
                 6  @prerelease
                 6  @source
                 6  @sources
                 5  @platforms
                 5  @specs
                 4  @base_dir
                 4  @canonical_segments
                 4  @full_require_paths
                 4  @gems_dir
                 4  @loaded_from
                 4  @platform
                 4  ID_INTERNAL(213)
                 3  @activated
                 3  @autorequire
                 3  @extension_dir
                 3  @extensions
                 3  @full_gem_path
                 3  @full_name
                 3  @gem_dir
                 3  @ignored
                 3  @new_platform
                 3  @require_paths
                 3  @requirements
                 3  @root
                 3  @ruby_version
                 3  @type
                 3  @ui
                 3  ID_INTERNAL(248)
                 2  @allow_cached
                 2  @allow_remote
                 2  @app_cache_path
                 2  @authors
                 2  @bar
                 2  @bin_dir
                 2  @bindir
                 2  @bundler_extension_dir
                 2  @bundler_version
                 2  @cache_dir
                 2  @cache_file
                 2  @cert_chain
                 2  @commands
                 2  @data
                 2  @date
                 2  @default_gem
                 2  @definition
                 2  @description
      EOS
    end

    private

    def fixtures_path(subpath)
      File.expand_path(File.join('../fixtures', subpath), __FILE__)
    end
  end
end
