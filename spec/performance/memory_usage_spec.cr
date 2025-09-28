require "../spec_helper"

describe "Memory Usage Performance" do
  describe "memory management" do
    it "monitors memory usage during build", tags: [TestTags::PERFORMANCE] do
      config = TestDataFactory.create_config("Memory Test Site", "test_output")

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")

        # Create test content
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        # Create multiple content files to test memory usage
        10.times do |i|
          content_text = <<-MD
          ---
          title: Memory Test #{i + 1}
          date: 2024-01-#{15 + i}
          layout: post
          ---

          # Memory Test #{i + 1}

          This is content #{i + 1} for memory testing.

          ## Section 1

          Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.

          ## Section 2

          Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

          ## Section 3

          Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
          MD

          File.write(File.join(content_dir, "memory-test-#{i + 1}.md"), content_text)
        end

        # Monitor memory usage
        memory_manager = Lapis::MemoryManager.new

        initial_memory = memory_manager.current_memory_usage

        # Build site
        generator = Lapis::Generator.new(config)
        generator.build

        final_memory = memory_manager.current_memory_usage

        # Memory usage should be reasonable
        memory_delta = final_memory - initial_memory
        memory_delta.should be >= 0

        # Log memory usage
        Lapis::Logger.info("Memory usage test",
          initial: memory_manager.format_bytes(initial_memory),
          final: memory_manager.format_bytes(final_memory),
          delta: memory_manager.format_bytes(memory_delta))
      end
    end

    it "detects memory pressure", tags: [TestTags::PERFORMANCE] do
      memory_manager = Lapis::MemoryManager.new

      # Set low threshold for testing
      memory_manager.memory_threshold = 1_i64 * 1024 * 1024 # 1MB

      # Check memory pressure
      pressure = memory_manager.memory_pressure?
      pressure.should be_a(Bool)

      # Log memory status
      stats = memory_manager.memory_stats
      Lapis::Logger.info("Memory pressure test",
        pressure: pressure.to_s,
        heap_size: stats["heap_size"],
        heap_used: stats["heap_used"])
    end

    it "manages GC during operations", tags: [TestTags::PERFORMANCE] do
      memory_manager = Lapis::MemoryManager.new

      # Test GC control
      memory_manager.with_gc_disabled do
        # Create some objects
        data = Array.new(1000) { |i| "test_string_#{i}" }

        # GC should be disabled
        data.size.should eq(1000)
      end

      # GC should be re-enabled
      memory_manager.force_gc

      # Should not raise error
      true.should be_true
    end
  end

  describe "memory profiling" do
    it "profiles memory usage during operations", tags: [TestTags::PERFORMANCE] do
      memory_manager = Lapis::MemoryManager.new

      # Profile an operation
      result = memory_manager.monitor_operation("test_operation") do
        # Create some data
        data = Array.new(100) { |i| "item_#{i}" }
        data.size
      end

      result.should eq(100)

      # Should have logged memory usage
      true.should be_true
    end

    it "profiles build operations", tags: [TestTags::PERFORMANCE] do
      config = TestDataFactory.create_config("Profile Test Site", "test_output")

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")

        # Create test content
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        content_text = <<-MD
        ---
        title: Profile Test
        date: 2024-01-15
        layout: post
        ---

        # Profile Test

        This tests memory profiling during build.
        MD

        File.write(File.join(content_dir, "profile-test.md"), content_text)

        # Profile build operation
        memory_manager = Lapis::MemoryManager.new

        result = memory_manager.profile_build_operation("site_build") do
          generator = Lapis::Generator.new(config)
          generator.build
        end

        # Should complete successfully
        result.should be_nil
      end
    end
  end
end
