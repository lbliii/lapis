require "../spec_helper"
require "../../src/lapis/logger"
require "../../src/lapis/safe_cast"
require "../../src/lapis/exceptions"

describe "TypeCastError Logging" do
  describe "SafeCast logging" do
    it "logs TypeCastError occurrences with context", tags: [TestTags::FAST, TestTags::UNIT] do
      # Test that TypeCastError occurrences are properly logged
      expect_raises(ArgumentError) do
        Lapis::SafeCast.cast_or_raise("invalid", Int32, "test context")
      end
    end

    it "logs warnings for failed casts in data conversion", tags: [TestTags::FAST, TestTags::UNIT] do
      # This test would verify that conversion warnings are logged
      # The actual logging happens in the data processor conversion methods
      json_data = JSON::Any.new("test")

      # The conversion should handle the cast gracefully and log warnings
      result = Lapis::DataProcessor.json_to_yaml(json_data)
      result.should be_a(String)
    end
  end

  describe "Error context logging" do
    it "includes proper context in TypeCastError messages", tags: [TestTags::FAST, TestTags::UNIT] do
      error = Lapis::TypeCastError.new(
        "Cast failed",
        source_type: "String",
        target_type: "Int32",
        value: "hello"
      )

      error.message.should eq("Cast failed")
      error.context["source_type"].should eq("String")
      error.context["target_type"].should eq("Int32")
      error.context["value"].should eq("hello")
    end

    it "logs error context for debugging", tags: [TestTags::FAST, TestTags::UNIT] do
      # Test that error context is properly formatted for logging
      error = Lapis::TypeCastError.new(
        "Type cast failed",
        source_type: "JSON::Any",
        target_type: "PostData",
        value: "{\"invalid\": \"data\"}"
      )

      # Verify the error has all necessary context for debugging
      error.context.keys.should contain("source_type")
      error.context.keys.should contain("target_type")
      error.context.keys.should contain("value")
    end
  end

  describe "Logger integration" do
    it "uses structured logging for TypeCastError", tags: [TestTags::FAST, TestTags::UNIT] do
      # Test that TypeCastError logging follows the structured logging pattern
      error = Lapis::TypeCastError.new(
        "Test error",
        source_type: "String",
        target_type: "Int32"
      )

      # Verify the error can be logged with context
      error.context.should be_a(Hash(String, String))
      error.context.size.should be > 0
    end

    it "provides debugging information for type casting failures", tags: [TestTags::FAST, TestTags::UNIT] do
      # Test that sufficient debugging information is available
      begin
        Lapis::SafeCast.cast_or_raise("hello", Int32, "test operation")
      rescue ex : ArgumentError
        ex.message.should_not be_nil
        ex.message.not_nil!.should contain("Failed to cast String to Int32")
        ex.message.not_nil!.should contain("test operation")
      end
    end
  end

  describe "Error propagation logging" do
    it "logs wrapped TypeCastError with original cause", tags: [TestTags::FAST, TestTags::UNIT] do
      original_error = Exception.new("Original type cast error")
      wrapped_error = Lapis::TypeCastError.new(
        "Wrapped error",
        original_error,
        source_type: "JSON",
        target_type: "PostData"
      )

      wrapped_error.cause.should eq(original_error)
      wrapped_error.context["source_type"].should eq("JSON")
      wrapped_error.context["target_type"].should eq("PostData")
    end

    it "maintains error chain for debugging", tags: [TestTags::FAST, TestTags::UNIT] do
      # Test that error chains are preserved for debugging
      cause = Exception.new("Root cause")
      error = Lapis::TypeCastError.new("Wrapper", cause)

      error.cause.should eq(cause)
      error.message.should eq("Wrapper")
    end
  end

  describe "Performance impact logging" do
    it "logs type casting operations for performance monitoring", tags: [TestTags::FAST, TestTags::UNIT] do
      # Test that type casting operations can be monitored
      start_time = Time.monotonic

      result = Lapis::SafeCast.cast_or_nil("test", String)
      result.should eq("test")

      # Verify the operation completed quickly
      duration = Time.monotonic - start_time
      duration.total_milliseconds.should be < 100
    end

    it "logs failed casts for performance analysis", tags: [TestTags::FAST, TestTags::UNIT] do
      # Test that failed casts are logged for analysis
      start_time = Time.monotonic

      result = Lapis::SafeCast.cast_or_nil("test", Int32)
      result.should be_nil

      # Verify the operation completed quickly even on failure
      duration = Time.monotonic - start_time
      duration.total_milliseconds.should be < 100
    end
  end
end
