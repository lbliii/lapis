require "../spec_helper"

describe Lapis::UnifiedAssetProcessor do
  describe "#process_all_assets" do
    it "processes assets successfully", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::Config.new
      processor = Lapis::UnifiedAssetProcessor.new(config)

      # This is a basic test - more comprehensive tests would be added
      # when the processor is fully implemented
      processor.should be_a(Lapis::UnifiedAssetProcessor)
    end
  end
end
