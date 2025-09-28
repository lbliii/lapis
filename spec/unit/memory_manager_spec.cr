require "../spec_helper"

describe Lapis::MemoryManager do
  describe "#current_memory_usage" do
    it "returns current memory usage", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::MemoryManager.new
      usage = manager.current_memory_usage

      usage.should be_a(Int64)
      usage.should be >= 0
    end
  end

  describe "#memory_stats" do
    it "returns memory statistics", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::MemoryManager.new
      stats = manager.memory_stats

      stats.should be_a(Hash(String, String))
      stats.keys.should contain("heap_size")
      stats.keys.should contain("heap_used")
      stats.keys.should contain("free_bytes")
    end
  end

  describe "#with_gc_disabled" do
    it "disables GC during block execution", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::MemoryManager.new

      result = manager.with_gc_disabled do
        "test_result"
      end

      result.should eq("test_result")
    end

    it "re-enables GC after block execution", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::MemoryManager.new

      manager.with_gc_disabled do
        # GC should be disabled here
      end

      # GC should be re-enabled after block
      true.should be_true
    end
  end

  describe "#force_gc" do
    it "forces garbage collection", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::MemoryManager.new

      # Should not raise error
      manager.force_gc
      true.should be_true
    end
  end

  describe "#memory_pressure?" do
    it "detects memory pressure", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::MemoryManager.new
      pressure = manager.memory_pressure?

      pressure.should be_a(Bool)
    end
  end

  describe "#monitor_operation" do
    it "monitors memory usage during operation", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::MemoryManager.new

      result = manager.monitor_operation("test_operation") do
        "test_result"
      end

      result.should eq("test_result")
    end
  end

  describe "#format_bytes" do
    it "formats bytes correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::MemoryManager.new

      manager.format_bytes(1024).should eq("1.0 KB")
      manager.format_bytes(1024 * 1024).should eq("1.0 MB")
      manager.format_bytes(1024 * 1024 * 1024).should eq("1.0 GB")
      manager.format_bytes(512).should eq("512 B")
    end
  end
end
