# frozen_string_literal: true

module HeapProfiler
  class Analyzer
    # Dumping the heap does allocates by itself

    # TODO: See with Aaron and Allan what they are and how to get rid of them
    # These two hashes are referenced by `"root":"machine_context"`. However `0x7fb0a5bcfc20` isn't in the dump.
    # {"address":"0x7fb0a280e5a8", "type":"HASH", "class":"0x7fb0a28951e8", "size":1, "references":["0x7fb0a5bcfc20"], "memsize":168, "flags":{"wb_protected":true}}
    # {"address":"0x7fb0a280e9e0", "type":"HASH", "class":"0x7fb0a28951e8", "size":1, "references":["0x7fb0a5bcfc20"], "memsize":168, "flags":{"wb_protected":true}}
    # No idea where that file come from.
    # {"address":"0x7fb0a5bcfdb0", "type":"FILE", "class":"0x7fb0a287f370", "fd":-1, "references":["0x7fb0a5bcfd88"], "memsize":232, "flags":{"uncollectible":true, "marked":true}}
    SIDE_EFFECT_ALLOCATIONS = 3
    SIDE_EFFECT_RETENTIONS = 1
    SIDE_EFFECT_RELEASES = 2

    def initialize(report_directory)
      @report_directory = report_directory
      @baseline = open_dump('baseline')
      @allocated = open_dump('allocated')
      @retained = open_dump('retained')
    end

    def allocated_objects_count
      allocated_diff.size - SIDE_EFFECT_ALLOCATIONS
    end

    def retained_objects_count
      retained_diff.size - SIDE_EFFECT_RETENTIONS
    end

    def freed_objects_count
      freed_diff.size - SIDE_EFFECT_RELEASES
    end

    def allocated_diff
      @allocated_diff ||= build_diff('allocated-diff', @baseline, @allocated)
    end

    def retained_diff
      @retained_diff ||= build_diff('retained-diff', @baseline, @retained)
    end

    def freed_diff
      @freed_diff ||= build_diff('freed-diff', @retained, @baseline)
    end

    private

    def build_diff(name, base, extra)
      diff = open_dump(name)
      unless diff.exist?
        File.open(diff.path, 'w+') do |f|
          extra.diff(base, f)
        end
      end
      diff
    end

    def open_dump(name)
      Dump.open(@report_directory, name)
    end
  end
end
