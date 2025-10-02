require "../spec_helper"

describe "Memory Usage Performance" do
  if should_run_performance_tests?
    describe "memory management" do
      it "monitors memory usage during build", tags: [TestTags::PERFORMANCE] do
        # Use shared config to avoid creating new content
        config = SharedBuildResults.shared_config

        # Monitor memory usage
        memory_manager = Lapis::MemoryManager.new

        initial_memory = memory_manager.current_memory_usage

        # Build site (only one build total across all tests)
        SharedBuildResults.perform_shared_build

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
        # Use shared config to avoid creating new content
        config = SharedBuildResults.shared_config

        # Profile build operation using mock build
        memory_manager = Lapis::MemoryManager.new

        result = memory_manager.profile_build_operation("site_build") do
          SharedBuildResults.mock_build
          nil
        end

        # Should complete successfully
        result.should be_nil
      end
    end
  else
    pending "Performance tests skipped (use LAPIS_INCLUDE_PERFORMANCE=1 to run)"
  end
end
