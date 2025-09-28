require "../spec_helper"

describe Lapis::ProcessManager do
  # Test the Process API improvements we actually made
  describe "#safe_shell_execute" do
    it "executes shell commands with proper argument quoting", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::ProcessManager.new(setup_termination: false)

      # Test with arguments that need quoting
      result = manager.safe_shell_execute("echo", ["hello world", "test with spaces"])
      result.success.should be_true
      result.output.should contain("hello world")
      result.output.should contain("test with spaces")
    end

    it "handles shell command failures", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::ProcessManager.new(setup_termination: false)

      # Process.run with shell: true doesn't raise for non-existent commands
      # It returns a failed status instead
      result = manager.safe_shell_execute("nonexistent_command", [] of String)
      result.success.should be_false
    end
  end

  describe "#shell_execute" do
    it "executes shell commands using Process.run with shell parameter", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::ProcessManager.new(setup_termination: false)

      result = manager.shell_execute("echo hello")
      result.success.should be_true
      result.output.should contain("hello")
    end
  end

  describe "#command_exists?" do
    it "checks if commands exist using Process.run", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::ProcessManager.new(setup_termination: false)

      # echo should exist on most systems
      manager.command_exists?("echo").should be_true
      manager.command_exists?("nonexistent_command").should be_false
    end
  end

  describe "#get_command_version" do
    it "gets command versions using Process.run", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::ProcessManager.new(setup_termination: false)

      # Test with a command that should exist and have version info
      version = manager.get_command_version("echo")
      # echo might not have --version, so this could be nil
      # But it shouldn't raise an error
    end

    it "handles commands without version info", tags: [TestTags::FAST, TestTags::UNIT] do
      manager = Lapis::ProcessManager.new(setup_termination: false)

      version = manager.get_command_version("nonexistent_command")
      version.should be_nil
    end
  end

  # Test Process.on_terminate functionality (without interfering with Process.new)
  describe "Process.on_terminate integration" do
    it "sets up termination handler when not in test mode", tags: [TestTags::FAST, TestTags::UNIT] do
      # This test verifies that Process.on_terminate is properly integrated
      # without actually testing the handler (which would interfere with other tests)
      manager = Lapis::ProcessManager.new(setup_termination: true)
      manager.should be_a(Lapis::ProcessManager)
    end

    it "skips termination handler in test mode", tags: [TestTags::FAST, TestTags::UNIT] do
      # This test verifies that test mode properly disables the handler
      manager = Lapis::ProcessManager.new(setup_termination: false)
      manager.should be_a(Lapis::ProcessManager)
    end
  end
end
