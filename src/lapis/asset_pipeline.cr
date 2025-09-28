require "file_utils"
require "compress/gzip"
require "digest/md5"
require "log"
require "./logger"
require "./exceptions"
require "./config"

module Lapis
  # Asset types for processing
  enum AssetType
    CSS
    JavaScript
    Image
    Font
    Other
  end

  # Asset processing result
  struct AssetResult
    property original_path : String
    property output_path : String
    property asset_type : AssetType
    property size_before : Int64
    property size_after : Int64
    property processing_time : Time::Span
    property success : Bool
    property error : String?

    def initialize(@original_path : String, @output_path : String, @asset_type : AssetType,
                   @size_before : Int64, @size_after : Int64, @processing_time : Time::Span,
                   @success : Bool, @error : String? = nil)
    end

    def compression_ratio : Float64
      return 0.0 if @size_before == 0
      (1.0 - (@size_after.to_f / @size_before.to_f)) * 100.0
    end
  end

  # Advanced Asset Pipeline
  class AssetPipeline
    property config : Config
    property results : Array(AssetResult) = [] of AssetResult
    property cache_dir : String
    property asset_cache : Hash(String, String) = {} of String => String

    def initialize(@config : Config)
      @cache_dir = File.join(@config.build_config.cache_dir, "assets")
      Dir.mkdir_p(@cache_dir)
      load_asset_cache
    end

    def process_all_assets : Array(AssetResult)
      Logger.info("Starting asset pipeline processing")
      start_time = Time.monotonic

      @results.clear

      # Find all assets
      assets = discover_assets
      Logger.info("Found #{assets.size} assets to process")

      # Process assets by type
      process_css_assets(assets.select { |a| a.type == AssetType::CSS })
      process_js_assets(assets.select { |a| a.type == AssetType::JavaScript })
      process_image_assets(assets.select { |a| a.type == AssetType::Image })
      process_font_assets(assets.select { |a| a.type == AssetType::Font })
      process_other_assets(assets.select { |a| a.type == AssetType::Other })

      # Save cache
      save_asset_cache

      total_time = Time.monotonic - start_time
      Logger.info("Asset pipeline completed",
        total_assets: @results.size.to_s,
        successful: @results.count(&.success).to_s,
        failed: @results.count { |r| !r.success }.to_s,
        total_time: "#{total_time.total_milliseconds}ms")

      log_compression_stats
      @results
    end

    def process_single_asset(asset_path : String) : AssetResult
      asset_info = AssetInfo.new(asset_path)

      case asset_info.type
      when .css?
        process_css_file(asset_info)
      when .javascript?
        process_js_file(asset_info)
      when .image?
        process_image_file(asset_info)
      when .font?
        process_font_file(asset_info)
      else
        process_other_file(asset_info)
      end
    end

    private def discover_assets : Array(PipelineAssetInfo)
      assets = [] of PipelineAssetInfo

      # Scan static directory
      if Dir.exists?(@config.static_dir)
        Dir.glob(File.join(@config.static_dir, "**/*")).each do |file_path|
          next unless File.file?(file_path)

          asset_info = PipelineAssetInfo.new(file_path)
          assets << asset_info
        end
      end

      # Scan theme assets
      theme_assets_dir = File.join("themes", @config.theme, "assets")
      if Dir.exists?(theme_assets_dir)
        Dir.glob(File.join(theme_assets_dir, "**/*")).each do |file_path|
          next unless File.file?(file_path)

          asset_info = PipelineAssetInfo.new(file_path)
          assets << asset_info
        end
      end

      assets
    end

    private def process_css_assets(css_assets : Array(PipelineAssetInfo))
      return if css_assets.empty?

      Logger.info("Processing #{css_assets.size} CSS assets")

      css_assets.each do |asset|
        result = process_css_file(asset)
        @results << result
      end
    end

    private def process_js_assets(js_assets : Array(PipelineAssetInfo))
      return if js_assets.empty?

      Logger.info("Processing #{js_assets.size} JavaScript assets")

      js_assets.each do |asset|
        result = process_js_file(asset)
        @results << result
      end
    end

    private def process_image_assets(image_assets : Array(PipelineAssetInfo))
      return if image_assets.empty?

      Logger.info("Processing #{image_assets.size} image assets")

      image_assets.each do |asset|
        result = process_image_file(asset)
        @results << result
      end
    end

    private def process_font_assets(font_assets : Array(PipelineAssetInfo))
      return if font_assets.empty?

      Logger.info("Processing #{font_assets.size} font assets")

      font_assets.each do |asset|
        result = process_font_file(asset)
        @results << result
      end
    end

    private def process_other_assets(other_assets : Array(PipelineAssetInfo))
      return if other_assets.empty?

      Logger.info("Processing #{other_assets.size} other assets")

      other_assets.each do |asset|
        result = process_other_file(asset)
        @results << result
      end
    end

    private def process_css_file(asset : PipelineAssetInfo) : AssetResult
      start_time = Time.monotonic
      original_size = File.size(asset.path)

      begin
        # Read CSS content
        css_content = File.read(asset.path)

        # Process CSS
        processed_css = process_css_content(css_content, asset.path)

        # Generate output path
        output_path = generate_output_path(asset, "css")

        # Create output directory
        Dir.mkdir_p(File.dirname(output_path))

        # Write processed CSS
        File.write(output_path, processed_css)

        # Compress if enabled
        if @config.build_config.parallel # Using parallel flag as compression flag for now
          compress_file(output_path)
        end

        processed_size = File.size(output_path)
        processing_time = Time.monotonic - start_time

        Logger.debug("Processed CSS",
          source: asset.path,
          output: output_path,
          compression: "#{((1.0 - processed_size.to_f / original_size.to_f) * 100).round(1)}%")

        AssetResult.new(asset.path, output_path, AssetType::CSS,
          original_size, processed_size, processing_time, true)
      rescue ex
        processing_time = Time.monotonic - start_time
        Logger.error("Failed to process CSS", file: asset.path, error: ex.message)

        AssetResult.new(asset.path, "", AssetType::CSS,
          original_size, 0, processing_time, false, ex.message)
      end
    end

    private def process_js_file(asset : PipelineAssetInfo) : AssetResult
      start_time = Time.monotonic
      original_size = File.size(asset.path)

      begin
        # Read JavaScript content
        js_content = File.read(asset.path)

        # Process JavaScript
        processed_js = process_js_content(js_content, asset.path)

        # Generate output path
        output_path = generate_output_path(asset, "js")

        # Create output directory
        Dir.mkdir_p(File.dirname(output_path))

        # Write processed JavaScript
        File.write(output_path, processed_js)

        # Compress if enabled
        if @config.build_config.parallel
          compress_file(output_path)
        end

        processed_size = File.size(output_path)
        processing_time = Time.monotonic - start_time

        Logger.debug("Processed JavaScript",
          source: asset.path,
          output: output_path,
          compression: "#{((1.0 - processed_size.to_f / original_size.to_f) * 100).round(1)}%")

        AssetResult.new(asset.path, output_path, AssetType::JavaScript,
          original_size, processed_size, processing_time, true)
      rescue ex
        processing_time = Time.monotonic - start_time
        Logger.error("Failed to process JavaScript", file: asset.path, error: ex.message)

        AssetResult.new(asset.path, "", AssetType::JavaScript,
          original_size, 0, processing_time, false, ex.message)
      end
    end

    private def process_image_file(asset : PipelineAssetInfo) : AssetResult
      start_time = Time.monotonic
      original_size = File.size(asset.path)

      begin
        # For now, just copy images (real optimization would require external tools)
        output_path = generate_output_path(asset, "images")

        # Create output directory
        Dir.mkdir_p(File.dirname(output_path))

        # Copy image file
        File.copy(asset.path, output_path)

        processed_size = File.size(output_path)
        processing_time = Time.monotonic - start_time

        Logger.debug("Processed image",
          source: asset.path,
          output: output_path)

        AssetResult.new(asset.path, output_path, AssetType::Image,
          original_size, processed_size, processing_time, true)
      rescue ex
        processing_time = Time.monotonic - start_time
        Logger.error("Failed to process image", file: asset.path, error: ex.message)

        AssetResult.new(asset.path, "", AssetType::Image,
          original_size, 0, processing_time, false, ex.message)
      end
    end

    private def process_font_file(asset : PipelineAssetInfo) : AssetResult
      start_time = Time.monotonic
      original_size = File.size(asset.path)

      begin
        # Copy font files as-is
        output_path = generate_output_path(asset, "fonts")

        # Create output directory
        Dir.mkdir_p(File.dirname(output_path))

        # Copy font file
        File.copy(asset.path, output_path)

        processed_size = File.size(output_path)
        processing_time = Time.monotonic - start_time

        Logger.debug("Processed font",
          source: asset.path,
          output: output_path)

        AssetResult.new(asset.path, output_path, AssetType::Font,
          original_size, processed_size, processing_time, true)
      rescue ex
        processing_time = Time.monotonic - start_time
        Logger.error("Failed to process font", file: asset.path, error: ex.message)

        AssetResult.new(asset.path, "", AssetType::Font,
          original_size, 0, processing_time, false, ex.message)
      end
    end

    private def process_other_file(asset : PipelineAssetInfo) : AssetResult
      start_time = Time.monotonic
      original_size = File.size(asset.path)

      begin
        # Copy other files as-is
        output_path = generate_output_path(asset, "assets")

        # Create output directory
        Dir.mkdir_p(File.dirname(output_path))

        # Copy file
        File.copy(asset.path, output_path)

        processed_size = File.size(output_path)
        processing_time = Time.monotonic - start_time

        Logger.debug("Processed asset",
          source: asset.path,
          output: output_path)

        AssetResult.new(asset.path, output_path, AssetType::Other,
          original_size, processed_size, processing_time, true)
      rescue ex
        processing_time = Time.monotonic - start_time
        Logger.error("Failed to process asset", file: asset.path, error: ex.message)

        AssetResult.new(asset.path, "", AssetType::Other,
          original_size, 0, processing_time, false, ex.message)
      end
    end

    # CSS Processing
    private def process_css_content(css_content : String, file_path : String) : String
      processed = css_content

      # Remove comments
      processed = remove_css_comments(processed)

      # Minify whitespace
      processed = minify_css_whitespace(processed)

      # Remove unnecessary semicolons
      processed = remove_unnecessary_semicolons(processed)

      # Optimize colors
      processed = optimize_css_colors(processed)

      processed
    end

    private def remove_css_comments(css : String) : String
      css.gsub(/\/\*.*?\*\//m, "")
    end

    private def minify_css_whitespace(css : String) : String
      css.gsub(/\s+/, " ")
        .gsub(/;\s*}/, "}")
        .gsub(/{\s*/m, "{")
        .gsub(/;\s*/m, ";")
        .strip
    end

    private def remove_unnecessary_semicolons(css : String) : String
      css.gsub(/;}/, "}")
    end

    private def optimize_css_colors(css : String) : String
      # Convert #ffffff to #fff, etc.
      css.gsub(/#([0-9a-fA-F])\1([0-9a-fA-F])\2([0-9a-fA-F])\3/, "#\\1\\2\\3")
    end

    # JavaScript Processing
    private def process_js_content(js_content : String, file_path : String) : String
      processed = js_content

      # Remove comments (simple approach)
      processed = remove_js_comments(processed)

      # Minify whitespace
      processed = minify_js_whitespace(processed)

      # Remove unnecessary semicolons
      processed = remove_js_semicolons(processed)

      processed
    end

    private def remove_js_comments(js : String) : String
      # Remove single-line comments
      js = js.gsub(/\/\/.*$/, "")
      # Remove multi-line comments
      js.gsub(/\/\*.*?\*\//m, "")
    end

    private def minify_js_whitespace(js : String) : String
      js.gsub(/\s+/, " ")
        .gsub(/\s*{\s*/m, "{")
        .gsub(/\s*}\s*/m, "}")
        .gsub(/\s*;\s*/m, ";")
        .strip
    end

    private def remove_js_semicolons(js : String) : String
      js.gsub(/;}/, "}")
    end

    # Utility methods
    private def generate_output_path(asset : PipelineAssetInfo, category : String) : String
      relative_path = get_relative_path(asset.path)

      # Add hash for cache busting
      content_hash = generate_content_hash(asset.path)
      name_with_hash = add_hash_to_filename(relative_path, content_hash)

      File.join(@config.output_dir, "assets", category, name_with_hash)
    end

    private def get_relative_path(full_path : String) : String
      # Extract relative path from static directory or theme
      if full_path.starts_with?(@config.static_dir)
        full_path[@config.static_dir.size + 1..]
      elsif full_path.starts_with?("themes")
        full_path
      else
        File.basename(full_path)
      end
    end

    private def generate_content_hash(file_path : String) : String
      content = File.read(file_path)
      Digest::MD5.hexdigest(content)[0..7]
    end

    private def add_hash_to_filename(path : String, hash : String) : String
      ext = File.extname(path)
      base = File.basename(path, ext)
      dir = File.dirname(path)

      if dir == "."
        "#{base}.#{hash}#{ext}"
      else
        File.join(dir, "#{base}.#{hash}#{ext}")
      end
    end

    private def compress_file(file_path : String)
      # Create compressed version using gzip
      compressed_path = "#{file_path}.gz"

      File.open(file_path, "r") do |input|
        File.open(compressed_path, "w") do |output|
          Compress::Gzip::Writer.open(output) do |gzip|
            IO.copy(input, gzip)
          end
        end
      end

      Logger.debug("Created compressed file", original: file_path, compressed: compressed_path)
    end

    private def load_asset_cache
      cache_file = File.join(@cache_dir, "asset_cache.yml")
      return unless File.exists?(cache_file)

      begin
        cache_data = YAML.parse(File.read(cache_file))
        cache_data.as_h.each do |key, value|
          @asset_cache[key.to_s] = value.to_s
        end
        Logger.debug("Loaded asset cache", entries: @asset_cache.size.to_s)
      rescue ex
        Logger.warn("Failed to load asset cache", error: ex.message)
      end
    end

    private def save_asset_cache
      cache_file = File.join(@cache_dir, "asset_cache.yml")
      File.write(cache_file, @asset_cache.to_yaml)
      Logger.debug("Saved asset cache", entries: @asset_cache.size.to_s)
    end

    private def log_compression_stats
      total_before = @results.sum(&.size_before)
      total_after = @results.sum(&.size_after)
      total_saved = total_before - total_after

      if total_before > 0
        compression_ratio = (total_saved.to_f / total_before.to_f) * 100.0
        Logger.info("Asset compression summary",
          total_size_before: "#{(total_before / 1024.0).round(1)}KB",
          total_size_after: "#{(total_after / 1024.0).round(1)}KB",
          space_saved: "#{(total_saved / 1024.0).round(1)}KB",
          compression_ratio: "#{compression_ratio.round(1)}%")
      end
    end
  end

  # Asset information helper
  struct PipelineAssetInfo
    property path : String
    property type : AssetType

    def initialize(@path : String)
      @type = determine_asset_type(@path)
    end

    private def determine_asset_type(path : String) : AssetType
      extension = File.extname(path).downcase

      case extension
      when ".css"
        AssetType::CSS
      when ".js", ".mjs", ".ts", ".jsx", ".tsx"
        AssetType::JavaScript
      when ".jpg", ".jpeg", ".png", ".gif", ".svg", ".webp", ".avif", ".bmp", ".ico"
        AssetType::Image
      when ".woff", ".woff2", ".ttf", ".otf", ".eot"
        AssetType::Font
      else
        AssetType::Other
      end
    end
  end
end
