require "../spec_helper"

describe Lapis::ProcessManager do
  describe "#execute" do
    it "runs simple commands successfully", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::ProcessManager.new

      # Test with echo command (should work on most systems)
      result = manager.execute("echo", ["hello"])
      result.success.should be_true
    end

    it "handles command failures", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::ProcessManager.new

      expect_raises(Lapis::ProcessError) do
        manager.execute("nonexistent_command", [] of String)
      end
    end

    it "handles command timeouts", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::ProcessManager.new

      expect_raises(Lapis::ProcessError) do
        manager.execute("sleep", ["10"], timeout: 1.second)
      end
    end
  end

  describe "#execute_async" do
    it "runs commands asynchronously", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::ProcessManager.new

      process_id = manager.execute_async("echo", ["hello"])
      process_id.should be_a(String)

      # Wait for completion
      result = manager.wait_for_process(process_id)
      result.should_not be_nil
      result.not_nil!.success.should be_true
    end

    it "handles async command failures", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::ProcessManager.new

      expect_raises(Lapis::ProcessError) do
        manager.execute_async("nonexistent_command", [] of String)
      end
    end
  end

  describe "#command_exists?" do
    it "checks if commands exist", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::ProcessManager.new

      # echo should exist on most systems
      manager.command_exists?("echo").should be_true
      manager.command_exists?("nonexistent_command").should be_false
    end
  end

  describe "process lifecycle" do
    it "manages process lifecycle correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::ProcessManager.new

      process_id = manager.execute_async("echo", ["test"])

      # Process should be running
      manager.running_processes.should contain(process_id)

      # Wait for completion
      result = manager.wait_for_process(process_id)
      result.should be_a(Lapis::ProcessResult)
      result.not_nil!.success.should be_true

      # Process should be finished
      manager.running_processes.should_not contain(process_id)
    end
  end

  describe "error handling" do
    it "provides meaningful error messages", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::ProcessManager.new

      begin
        manager.execute("nonexistent_command", [] of String)
        fail("Should have raised ProcessError")
      rescue ex : Lapis::ProcessError
        ex.message.should_not be_nil
        ex.message.not_nil!.should contain("nonexistent_command")
      end
    end

    it "handles timeout errors", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::ProcessManager.new

      begin
        manager.execute("sleep", ["10"], timeout: 100.milliseconds)
        fail("Should have raised ProcessError")
      rescue ex : Lapis::ProcessError
        ex.message.should_not be_nil
        ex.message.not_nil!.should contain("timed out")
      end
    end
  end
end
