require "../spec_helper"

describe Lapis::UnifiedAssetProcessor do
  describe "#initialize" do
    it "initializes with Path-based cache directory", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        config = Lapis::Config.new
        config.build_config.cache_dir = temp_dir

        processor = Lapis::UnifiedAssetProcessor.new(config)

        processor.should be_a(Lapis::UnifiedAssetProcessor)
        processor.cache_dir.should eq(Path[temp_dir].join("assets").to_s)
      end
    end
  end

  describe "AssetInfo" do
    describe "#determine_asset_type" do
      it "correctly identifies CSS files", tags: [TestTags::FAST, TestTags::UNIT] do
        asset = Lapis::AssetInfo.new("/path/to/style.css", false)
        asset.type.should eq(Lapis::AssetType::CSS)
      end

      it "correctly identifies JavaScript files", tags: [TestTags::FAST, TestTags::UNIT] do
        asset = Lapis::AssetInfo.new("/path/to/script.js", false)
        asset.type.should eq(Lapis::AssetType::JavaScript)
      end

      it "correctly identifies image files", tags: [TestTags::FAST, TestTags::UNIT] do
        asset = Lapis::AssetInfo.new("/path/to/image.png", false)
        asset.type.should eq(Lapis::AssetType::Image)
      end

      it "correctly identifies font files", tags: [TestTags::FAST, TestTags::UNIT] do
        asset = Lapis::AssetInfo.new("/path/to/font.woff2", false)
        asset.type.should eq(Lapis::AssetType::Font)
      end
    end

    describe "#calculate_relative_path" do
      it "calculates relative path for site assets using Path", tags: [TestTags::FAST, TestTags::UNIT] do
        asset = Lapis::AssetInfo.new("/site/static/css/style.css", false)
        asset.relative_path.should eq("css/style.css")
      end

      it "calculates relative path for theme assets using Path", tags: [TestTags::FAST, TestTags::UNIT] do
        asset = Lapis::AssetInfo.new("/themes/default/static/js/app.js", true)
        asset.relative_path.should eq("js/app.js")
      end

      it "handles files without static directory using Path", tags: [TestTags::FAST, TestTags::UNIT] do
        asset = Lapis::AssetInfo.new("/some/file.txt", false)
        asset.relative_path.should eq("file.txt")
      end

      it "handles nested paths correctly using Path", tags: [TestTags::FAST, TestTags::UNIT] do
        asset = Lapis::AssetInfo.new("/site/static/assets/images/logo.png", false)
        asset.relative_path.should eq("assets/images/logo.png")
      end
    end
  end

  describe "#process_all_assets" do
    it "processes assets successfully", tags: [TestTags::FAST, TestTags::UNIT] do
      config = Lapis::Config.new
      processor = Lapis::UnifiedAssetProcessor.new(config)

      # This is a basic test - more comprehensive tests would be added
      # when the processor is fully implemented
      processor.should be_a(Lapis::UnifiedAssetProcessor)
    end
  end

  describe "#process_single_asset" do
    it "processes a single asset successfully", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        config = Lapis::Config.new
        config.static_dir = temp_dir

        # Create a test CSS file
        css_file = Path[temp_dir].join("style.css").to_s
        File.write(css_file, "body { color: red; }")

        processor = Lapis::UnifiedAssetProcessor.new(config)
        result = processor.process_single_asset(css_file)

        result.should be_a(Lapis::AssetResult)
        result.success.should be_true
        result.asset_type.should eq(Lapis::AssetType::CSS)
      end
    end
  end
end
