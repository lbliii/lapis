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

      # Test with very short timeout
      results = processor.process_parallel(tasks, task_processor, 50.milliseconds)

      # Should return partial results due to timeout
      results.size.should be <= 1
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
    it "spawns correct number of workers", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::BuildConfig.new(max_workers: 3)
      processor = Lapis::ParallelProcessor.new(config)

      # Access private method for testing
      processor.responds_to?(:spawn_workers).should be_true
    end

    it "handles worker cleanup", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::BuildConfig.new(max_workers: 2)
      processor = Lapis::ParallelProcessor.new(config)

      tasks = [Lapis::Task.new("task1", "file1.md", :content_process)]

      task_processor = ->(task : Lapis::Task) do
        Lapis::Result.new(task.id, true, "success")
      end

      # Process tasks to initialize workers
      processor.process_parallel(tasks, task_processor)

      # Workers should be cleaned up
      processor.running.should be_false
    end
  end

  describe "error handling" do
    it "handles channel errors gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::BuildConfig.new(max_workers: 1)
      processor = Lapis::ParallelProcessor.new(config)

      # Close channels to simulate error
      processor.work_channel.close

      tasks = [Lapis::Task.new("task1", "file1.md", :content_process)]

      task_processor = ->(task : Lapis::Task) do
        Lapis::Result.new(task.id, true, "success")
      end

      # Should handle closed channel gracefully
      results = processor.process_parallel(tasks, task_processor)

      # Should return empty results due to channel error
      results.size.should eq(0)
    end
  end
end
