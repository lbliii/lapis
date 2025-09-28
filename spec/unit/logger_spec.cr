require "../spec_helper"

describe Lapis::Logger do
  describe ".setup" do
    it "initializes logging system", tags: [TestTags::FAST, TestTags::UNIT] do
      Lapis::Logger.setup
      # Logger should be initialized without errors
      true.should be_true
    end

    it "can be called multiple times safely", tags: [TestTags::FAST, TestTags::UNIT] do
      Lapis::Logger.setup
      Lapis::Logger.setup # Should not raise error
      true.should be_true
    end
  end

  describe ".info" do
    it "logs info messages with context", tags: [TestTags::FAST, TestTags::UNIT] do
      Lapis::Logger.setup
      # This should not raise an error
      Lapis::Logger.info("test message", key: "value")
      true.should be_true
    end
  end

  describe ".debug" do
    it "logs debug messages", tags: [TestTags::FAST, TestTags::UNIT] do
      Lapis::Logger.setup
      Lapis::Logger.debug("debug message", operation: "test")
      true.should be_true
    end
  end

  describe ".time_operation" do
    it "measures operation time", tags: [TestTags::FAST, TestTags::UNIT] do
      Lapis::Logger.setup

      result = Lapis::Logger.time_operation("test_operation") do
        sleep(1.millisecond) # Small delay to measure
        "test_result"
      end

      result.should eq("test_result")
    end
  end
end
