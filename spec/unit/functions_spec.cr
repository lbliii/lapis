require "../spec_helper"

describe Lapis::Functions do
  describe ".setup" do
    it "registers all function categories", tags: [TestTags::FAST, TestTags::UNIT] do
      Lapis::Functions.setup

      # Check that functions are registered
      Lapis::Functions.function_list.size.should be > 0
    end
  end

  describe ".call" do
    it "calls registered functions", tags: [TestTags::FAST, TestTags::UNIT] do
      Lapis::Functions.setup

      # Test string functions
      result = Lapis::Functions.call("upper", ["hello"])
      result.should eq("HELLO")

      result = Lapis::Functions.call("lower", ["WORLD"])
      result.should eq("world")
    end

    it "returns empty string for unknown functions", tags: [TestTags::FAST, TestTags::UNIT] do
      Lapis::Functions.setup

      result = Lapis::Functions.call("unknown_function", [] of String)
      result.should eq("")
    end
  end

  describe ".has_function?" do
    it "checks if function exists", tags: [TestTags::FAST, TestTags::UNIT] do
      Lapis::Functions.setup

      Lapis::Functions.has_function?("upper").should be_true
      Lapis::Functions.has_function?("unknown_function").should be_false
    end
  end

  describe ".function_list" do
    it "returns list of available functions", tags: [TestTags::FAST, TestTags::UNIT] do
      Lapis::Functions.setup

      functions = Lapis::Functions.function_list
      functions.should be_a(Array(String))
      functions.size.should be > 0
    end
  end

  describe "string functions" do
    before_each do
      Lapis::Functions.setup
    end

    it "uppercase function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("upper", ["hello world"])
      result.should eq("HELLO WORLD")
    end

    it "lowercase function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("lower", ["HELLO WORLD"])
      result.should eq("hello world")
    end

    it "title case function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("title", ["hello world"])
      result.should eq("Hello World")
    end

    it "slugify function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("slugify", ["Hello World!"])
      result.should eq("hello-world")
    end

    it "trim function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("trim", ["  spaced  "])
      result.should eq("spaced")
    end

    it "truncate function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("truncate", ["This is a long string", "10", "..."])
      result.should eq("This is...")
    end
  end

  describe "math functions" do
    before_each do
      Lapis::Functions.setup
    end

    it "add function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("add", ["2", "3"])
      result.should eq("5.0")
    end

    it "subtract function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("subtract", ["10", "3"])
      result.should eq("7.0")
    end

    it "multiply function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("multiply", ["4", "5"])
      result.should eq("20.0")
    end

    it "len function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("len", ["hello"])
      result.should eq("5")
    end
  end

  describe "time functions" do
    before_each do
      Lapis::Functions.setup
    end

    it "now function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("now", [] of String)
      result.should be_a(String)
      result.should_not be_empty
    end

    it "date function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("date", ["%Y-%m-%d"])
      result.should be_a(String)
      result.should match(/\d{4}-\d{2}-\d{2}/)
    end
  end

  describe "file functions" do
    before_each do
      Lapis::Functions.setup
    end

    it "file_basename function works with Path", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("file_basename", ["/path/to/file.txt"])
      result.should eq("file.txt")

      result = Lapis::Functions.call("file_basename", ["/path/to/nested/file.md"])
      result.should eq("file.md")
    end

    it "file_dirname function works with Path", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("file_dirname", ["/path/to/file.txt"])
      result.should eq("/path/to")

      result = Lapis::Functions.call("file_dirname", ["/path/to/nested/file.md"])
      result.should eq("/path/to/nested")
    end

    it "file_extname function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("file_extname", ["file.txt"])
      result.should eq(".txt")

      result = Lapis::Functions.call("file_extname", ["file.md"])
      result.should eq(".md")
    end

    it "handles edge cases for file functions", tags: [TestTags::FAST, TestTags::UNIT] do
      # Empty path
      result = Lapis::Functions.call("file_basename", [""])
      result.should eq("")

      result = Lapis::Functions.call("file_dirname", [""])
      result.should eq(".")

      # Root path
      result = Lapis::Functions.call("file_dirname", ["/"])
      result.should eq("/")
    end
  end

  describe "logic functions" do
    before_each do
      Lapis::Functions.setup
    end

    it "eq function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("eq", ["hello", "hello"])
      result.should eq("true")

      result = Lapis::Functions.call("eq", ["hello", "world"])
      result.should eq("false")
    end

    it "ne function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("ne", ["hello", "world"])
      result.should eq("true")

      result = Lapis::Functions.call("ne", ["hello", "hello"])
      result.should eq("false")
    end

    it "and function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("and", ["true", "true"])
      result.should eq("true")

      result = Lapis::Functions.call("and", ["true", ""])
      result.should eq("false")
    end

    it "or function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("or", ["true", ""])
      result.should eq("true")

      result = Lapis::Functions.call("or", ["", ""])
      result.should eq("false")
    end

    it "contains function works", tags: [TestTags::FAST, TestTags::UNIT] do
      result = Lapis::Functions.call("contains", ["hello world", "world"])
      result.should eq("true")

      result = Lapis::Functions.call("contains", ["hello world", "goodbye"])
      result.should eq("false")
    end
  end
end
