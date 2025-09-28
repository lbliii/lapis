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
    it "uppercase function works", tags: [TestTags::FAST, TestTags::UNIT] do
      Lapis::Functions.setup

      result = Lapis::Functions.call("upper", ["hello world"])
      result.should eq("HELLO WORLD")
    end

    it "lowercase function works", tags: [TestTags::FAST, TestTags::UNIT] do
      Lapis::Functions.setup

      result = Lapis::Functions.call("lower", ["HELLO WORLD"])
      result.should eq("hello world")
    end

    it "title case function works", tags: [TestTags::FAST, TestTags::UNIT] do
      Lapis::Functions.setup

      result = Lapis::Functions.call("title", ["hello world"])
      result.should eq("Hello World")
    end
  end

  describe "math functions" do
    it "add function works", tags: [TestTags::FAST, TestTags::UNIT] do
      Lapis::Functions.setup

      result = Lapis::Functions.call("add", ["2", "3"])
      result.should eq("5")
    end
  end

  describe "time functions" do
    it "now function works", tags: [TestTags::FAST, TestTags::UNIT] do
      Lapis::Functions.setup

      result = Lapis::Functions.call("now", [] of String)
      result.should be_a(String)
    end
  end
end
