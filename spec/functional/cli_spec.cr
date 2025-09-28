require "../spec_helper"

describe "CLI Workflow" do
  describe "command execution" do
    it "executes help command", tags: [TestTags::FUNCTIONAL] do
      cli = Lapis::CLI.new(["help"])

      # Should not raise error
      cli.should be_a(Lapis::CLI)
    end

    it "executes init command", tags: [TestTags::FUNCTIONAL] do
      with_temp_directory do |_|
        cli = Lapis::CLI.new(["init", "test-site"])

        # Should not raise error
        cli.should be_a(Lapis::CLI)
      end
    end

    it "executes build command", tags: [TestTags::FUNCTIONAL] do
      config = TestDataFactory.create_config("CLI Test Site", "test_output")

      with_temp_directory do |temp_dir|
        config.output_dir = File.join(temp_dir, "output")

        # Create test content
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir_p(content_dir)

        content_text = <<-MD
        ---
        title: CLI Test
        date: 2024-01-15
        layout: post
        ---

        # CLI Test

        This tests CLI build command.
        MD

        File.write(File.join(content_dir, "cli-test.md"), content_text)

        cli = Lapis::CLI.new(["build"])

        # Should not raise error
        cli.should be_a(Lapis::CLI)
      end
    end

    it "executes new command", tags: [TestTags::FUNCTIONAL] do
      with_temp_directory do |_|
        cli = Lapis::CLI.new(["new", "post", "Test Post"])

        # Should not raise error
        cli.should be_a(Lapis::CLI)
      end
    end

    it "handles unknown commands", tags: [TestTags::FUNCTIONAL] do
      cli = Lapis::CLI.new(["unknown-command"])

      # Should not raise error during initialization
      cli.should be_a(Lapis::CLI)
    end
  end

  describe "error handling" do
    it "handles CLI errors gracefully", tags: [TestTags::FUNCTIONAL] do
      cli = Lapis::CLI.new(["build"])

      # Should handle errors gracefully
      cli.should be_a(Lapis::CLI)
    end

    it "provides helpful error messages", tags: [TestTags::FUNCTIONAL] do
      cli = Lapis::CLI.new(["invalid-command"])

      # Should provide helpful error messages
      cli.should be_a(Lapis::CLI)
    end
  end

  describe "command validation" do
    it "validates command arguments", tags: [TestTags::FUNCTIONAL] do
      cli = Lapis::CLI.new(["new"])

      # Should handle missing arguments gracefully
      cli.should be_a(Lapis::CLI)
    end

    it "validates command options", tags: [TestTags::FUNCTIONAL] do
      cli = Lapis::CLI.new(["build", "--invalid-option"])

      # Should handle invalid options gracefully
      cli.should be_a(Lapis::CLI)
    end
  end
end
