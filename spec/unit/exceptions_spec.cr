require "../spec_helper"

describe "Lapis Exceptions" do
  describe "LapisError" do
    it "creates error with message and context", tags: [TestTags::FAST, TestTags::UNIT] do
      context = {"file" => "test.md", "operation" => "load"}
      error = Lapis::LapisError.new("Test error", context)

      error.message.should eq("Test error")
      error.context.should eq(context)
    end

    it "creates error with empty context", tags: [TestTags::FAST, TestTags::UNIT] do
      error = Lapis::LapisError.new("Test error")

      error.message.should eq("Test error")
      error.context.should eq({} of String => String)
    end
  end

  describe "ConfigError" do
    it "inherits from LapisError", tags: [TestTags::FAST, TestTags::UNIT] do
      error = Lapis::ConfigError.new("Config error")

      error.should be_a(Lapis::LapisError)
      error.message.should eq("Config error")
    end

    it "can have file path context", tags: [TestTags::FAST, TestTags::UNIT] do
      error = Lapis::ConfigError.new("Config error", "config.yml")

      error.context["file"].should eq("config.yml")
    end
  end

  describe "ContentError" do
    it "inherits from LapisError", tags: [TestTags::FAST, TestTags::UNIT] do
      error = Lapis::ContentError.new("Content error")

      error.should be_a(Lapis::LapisError)
      error.message.should eq("Content error")
    end

    it "can have file path context", tags: [TestTags::FAST, TestTags::UNIT] do
      error = Lapis::ContentError.new("Content error", "test.md")

      error.context["file"].should eq("test.md")
    end
  end

  describe "TemplateError" do
    it "inherits from LapisError", tags: [TestTags::FAST, TestTags::UNIT] do
      error = Lapis::TemplateError.new("Template error")

      error.should be_a(Lapis::LapisError)
      error.message.should eq("Template error")
    end
  end

  describe "BuildError" do
    it "inherits from LapisError", tags: [TestTags::FAST, TestTags::UNIT] do
      error = Lapis::BuildError.new("Build error")

      error.should be_a(Lapis::LapisError)
      error.message.should eq("Build error")
    end

    it "can have build phase context", tags: [TestTags::FAST, TestTags::UNIT] do
      error = Lapis::BuildError.new("Build error", "content_loading")

      error.context["phase"].should eq("content_loading")
    end
  end

  describe "ServerError" do
    it "inherits from LapisError", tags: [TestTags::FAST, TestTags::UNIT] do
      error = Lapis::ServerError.new("Server error")

      error.should be_a(Lapis::LapisError)
      error.message.should eq("Server error")
    end

    it "can have server context", tags: [TestTags::FAST, TestTags::UNIT] do
      error = Lapis::ServerError.new("Server error", 3000, "localhost")

      error.context["port"].should eq("3000")
      error.context["host"].should eq("localhost")
    end
  end

  describe "FileSystemError" do
    it "inherits from LapisError", tags: [TestTags::FAST, TestTags::UNIT] do
      error = Lapis::FileSystemError.new("File system error")

      error.should be_a(Lapis::LapisError)
      error.message.should eq("File system error")
    end

    it "can have file path context", tags: [TestTags::FAST, TestTags::UNIT] do
      error = Lapis::FileSystemError.new("File system error", "test.md", "read")

      error.context["file"].should eq("test.md")
      error.context["operation"].should eq("read")
    end
  end

  describe "WebSocketError" do
    it "inherits from LapisError", tags: [TestTags::FAST, TestTags::UNIT] do
      error = Lapis::WebSocketError.new("WebSocket error")

      error.should be_a(Lapis::LapisError)
      error.message.should eq("WebSocket error")
    end
  end

  describe "AssetError" do
    it "inherits from LapisError", tags: [TestTags::FAST, TestTags::UNIT] do
      error = Lapis::AssetError.new("Asset error")

      error.should be_a(Lapis::LapisError)
      error.message.should eq("Asset error")
    end
  end

  describe "ValidationError" do
    it "inherits from LapisError", tags: [TestTags::FAST, TestTags::UNIT] do
      error = Lapis::ValidationError.new("Validation error")

      error.should be_a(Lapis::LapisError)
      error.message.should eq("Validation error")
    end

    it "can have validation context", tags: [TestTags::FAST, TestTags::UNIT] do
      error = Lapis::ValidationError.new("Validation error", "field_name", "invalid_data")

      error.context["field"].should eq("field_name")
      error.context["value"].should eq("invalid_data")
    end
  end

  describe "ProcessError" do
    it "inherits from LapisError", tags: [TestTags::FAST, TestTags::UNIT] do
      error = Lapis::ProcessError.new("Process error")

      error.should be_a(Lapis::LapisError)
      error.message.should eq("Process error")
    end

    it "can have process context", tags: [TestTags::FAST, TestTags::UNIT] do
      error = Lapis::ProcessError.new("Process error", "test_command", 1)

      error.context["command"].should eq("test_command")
      error.context["exit_code"].should eq("1")
    end
  end
end
