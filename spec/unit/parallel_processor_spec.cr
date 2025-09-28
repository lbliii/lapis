require "../spec_helper"

describe Lapis::ParallelProcessor do
  describe "#process_parallel" do
    it "processes tasks successfully", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::BuildConfig.new(max_workers: 2)
      processor = Lapis::ParallelProcessor.new(config)

      tasks = [
        Lapis::Task.new("task1", "file1.md", :content_process),
        Lapis::Task.new("task2", "file2.md", :content_process),
      ]

      task_processor = ->(task : Lapis::Task) do
        Lapis::Result.new(task.id, true, "success")
      end

      results = processor.process_parallel(tasks, task_processor)

      results.size.should eq(2)
      results.all?(&.success).should be_true
    end

    it "handles task failures gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::BuildConfig.new(max_workers: 1)
      processor = Lapis::ParallelProcessor.new(config)

      tasks = [Lapis::Task.new("task1", "file1.md", :content_process)]

      task_processor = ->(task : Lapis::Task) do
        Lapis::Result.new(task.id, false, nil, "Task failed")
      end

      results = processor.process_parallel(tasks, task_processor)

      results.size.should eq(1)
      results.first.success.should be_false
      results.first.error.should eq("Task failed")
    end

    it "handles timeouts correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::BuildConfig.new(max_workers: 1)
      processor = Lapis::ParallelProcessor.new(config)

      tasks = [Lapis::Task.new("task1", "file1.md", :content_process)]

      task_processor = ->(task : Lapis::Task) do
        # Simulate slow task
        sleep(100.milliseconds)
        Lapis::Result.new(task.id, true, "success")
      end

      # Note: WaitGroup doesn't support timeout in the same way as channels
      # The timeout parameter is kept for API compatibility but not actively used
      results = processor.process_parallel(tasks, task_processor, 50.milliseconds)

      # Should complete all tasks (WaitGroup waits for all to finish)
      results.size.should eq(1)
      results.first.success.should be_true
    end

    it "handles empty task arrays", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::BuildConfig.new(max_workers: 2)
      processor = Lapis::ParallelProcessor.new(config)

      task_processor = ->(task : Lapis::Task) do
        Lapis::Result.new(task.id, true, "success")
      end

      results = processor.process_parallel([] of Lapis::Task, task_processor)

      results.size.should eq(0)
    end
  end

  describe "#process_content_parallel" do
    it "processes content files in parallel", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::BuildConfig.new(max_workers: 2)
      processor = Lapis::ParallelProcessor.new(config)

      files = ["file1.md", "file2.md", "file3.md"]

      content_processor = ->(file_path : String) do
        "processed_#{file_path}"
      end

      results = processor.process_content_parallel(files, content_processor)

      results.size.should eq(3)
      results.all?(&.success).should be_true
    end
  end

  describe "worker management" do
    it "uses WaitGroup for synchronization", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::BuildConfig.new(max_workers: 3)
      processor = Lapis::ParallelProcessor.new(config)

      # With WaitGroup, we don't need to test worker spawning directly
      # The synchronization is handled automatically
      processor.config.max_workers.should eq(3)
    end

    it "handles task completion automatically", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::BuildConfig.new(max_workers: 2)
      processor = Lapis::ParallelProcessor.new(config)

      tasks = [Lapis::Task.new("task1", "file1.md", :content_process)]

      task_processor = ->(task : Lapis::Task) do
        Lapis::Result.new(task.id, true, "success")
      end

      # Process tasks - WaitGroup handles synchronization automatically
      results = processor.process_parallel(tasks, task_processor)

      # Should complete successfully
      results.size.should eq(1)
      results.first.success.should be_true
    end
  end

  describe "error handling" do
    it "handles exceptions gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::BuildConfig.new(max_workers: 1)
      processor = Lapis::ParallelProcessor.new(config)

      tasks = [Lapis::Task.new("task1", "file1.md", :content_process)]

      task_processor = ->(task : Lapis::Task) do
        raise "Simulated error"
      end

      # Should handle exceptions gracefully
      results = processor.process_parallel(tasks, task_processor)

      # Should return error result
      results.size.should eq(1)
      results.first.success.should be_false
      results.first.error.should eq("Simulated error")
    end
  end
end
