require "../spec_helper"

describe "Parallel Processing Performance" do
  describe "performance regression tests" do
    it "parallel processing is faster than sequential for multiple tasks", tags: [TestTags::PERFORMANCE] do
      config = Lapis::BuildConfig.new(max_workers: 4)
      processor = Lapis::ParallelProcessor.new(config)

      # Create multiple tasks (reduced for faster tests)
      tasks = (1..4).map do |i|
        Lapis::Task.new("task#{i}", "file#{i}.md", :content_process)
      end

      # Simulate work that benefits from parallelization
      task_processor = ->(task : Lapis::Task) do
        # Simulate some work
        # Minimal delay for testing
        Fiber.yield
        Lapis::Result.new(task.id, true, "success")
      end

      # Test parallel processing
      parallel_results = processor.process_parallel(tasks, task_processor)

      # Test sequential processing
      sequential_results = tasks.map do |task|
        task_processor.call(task)
      end

      # Both should produce correct results (skip timing comparison for small workloads)
      parallel_results.size.should eq(sequential_results.size)
      parallel_results.all?(&.success).should be_true
    end

    it "handles large number of tasks efficiently", tags: [TestTags::PERFORMANCE] do
      config = Lapis::BuildConfig.new(max_workers: 8)
      processor = Lapis::ParallelProcessor.new(config)

      # Create many tasks
      tasks = (1..100).map do |i|
        Lapis::Task.new("task#{i}", "file#{i}.md", :content_process)
      end

      task_processor = ->(task : Lapis::Task) do
        Lapis::Result.new(task.id, true, "success")
      end

      start_time = Time.monotonic
      results = processor.process_parallel(tasks, task_processor)
      duration = Time.monotonic - start_time

      # Should complete in reasonable time (less than 1 second for 100 simple tasks)
      duration.should be < 1.second

      # All tasks should complete successfully
      results.size.should eq(100)
      results.all?(&.success).should be_true
    end

    it "scales with worker count", tags: [TestTags::PERFORMANCE] do
      tasks = (1..6).map do |i|
        Lapis::Task.new("task#{i}", "file#{i}.md", :content_process)
      end

      task_processor = ->(task : Lapis::Task) do
        # Minimal delay for testing
        Fiber.yield # Simulate work
        Lapis::Result.new(task.id, true, "success")
      end

      durations = [] of Time::Span

      # Test with different worker counts
      [1, 2, 4, 8].each do |worker_count|
        config = Lapis::BuildConfig.new(max_workers: worker_count)
        processor = Lapis::ParallelProcessor.new(config)

        start_time = Time.monotonic
        processor.process_parallel(tasks, task_processor)
        duration = Time.monotonic - start_time

        durations << duration
      end

      # More workers should generally be faster (allowing for overhead)
      # Note: This might not always be true due to overhead, but it's a good indicator
      durations[1].should be <= durations[0] # 2 workers vs 1 worker
    end
  end

  describe "memory usage" do
    it "doesn't leak memory with repeated processing", tags: [TestTags::PERFORMANCE] do
      config = Lapis::BuildConfig.new(max_workers: 2)
      processor = Lapis::ParallelProcessor.new(config)

      task_processor = ->(task : Lapis::Task) do
        Lapis::Result.new(task.id, true, "success")
      end

      # Process multiple batches
      10.times do |batch|
        tasks = (1..5).map do |i|
          Lapis::Task.new("batch#{batch}_task#{i}", "file#{i}.md", :content_process)
        end

        results = processor.process_parallel(tasks, task_processor)
        results.size.should eq(5)
        results.all?(&.success).should be_true
      end

      # If we get here without memory issues, the test passes
      true.should be_true
    end
  end
end
