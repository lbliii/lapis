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

  # Asset information for processing
  struct AssetInfo
    property path : String
    property type : AssetType
    property is_theme_asset : Bool
    property relative_path : String

    def initialize(@path : String, @is_theme_asset : Bool)
      @type = determine_asset_type(@path)
      @relative_path = calculate_relative_path(@path, @is_theme_asset)
    end

    private def determine_asset_type(file_path : String) : AssetType
      ext = File.extname(file_path).downcase
      case ext
      when ".css"
        AssetType::CSS
      when ".js"
        AssetType::JavaScript
      when ".jpg", ".jpeg", ".png", ".gif", ".svg", ".webp"
        AssetType::Image
      when ".woff", ".woff2", ".ttf", ".eot"
        AssetType::Font
      else
        AssetType::Other
      end
    end

    private def calculate_relative_path(file_path : String, is_theme_asset : Bool) : String
      if is_theme_asset
        # For theme assets, extract path after themes/default/static/
        # file_path: /path/to/themes/default/static/css/style.css
        # We want: css/style.css
        parts = file_path.split("/")
        static_index = parts.index("static")
        if static_index && static_index + 1 < parts.size
          parts[static_index + 1..].join("/")
        else
          Path[file_path].basename
        end
      else
        # For site assets, extract path after static/
        # file_path: /path/to/site/static/css/style.css
        # We want: css/style.css
        parts = file_path.split("/")
        static_index = parts.index("static")
        if static_index && static_index + 1 < parts.size
          parts[static_index + 1..].join("/")
        else
          Path[file_path].basename
        end
      end
    end
  end

  # Unified Asset Processor - Single system for all asset processing
  class UnifiedAssetProcessor
    property config : Config
    property results : Array(AssetResult) = [] of AssetResult
    property cache_dir : String
    property asset_cache : Hash(String, String) = {} of String => String
    property max_results_size : Int32 = 5000
    property max_cache_size : Int32 = 1000

    def initialize(@config : Config)
      @cache_dir = Path[@config.build_config.cache_dir].join("assets").to_s
      Dir.mkdir_p(@cache_dir)
      load_asset_cache
    end

    def process_all_assets : Array(AssetResult)
      Logger.info("Starting unified asset processing")
      start_time = Time.monotonic

      @results.clear

      # Check memory before processing
      memory_manager = Lapis.memory_manager
      memory_manager.check_collection_size("asset_results", @results.size)

      # Discover all assets
      assets = discover_all_assets
        .tap { |discovered| Logger.info("Found #{discovered.size} assets to process") }
        .tap { |discovered| Logger.debug("Asset types", types: discovered.map(&.type).uniq) }

      # Process assets by type
      process_assets_by_type(assets)

      # Save cache
      save_asset_cache

      total_time = Time.monotonic - start_time
      Logger.info("Unified asset processing completed",
        total_assets: @results.size.to_s,
        successful: @results.count(&.success).to_s,
        failed: @results.count { |r| !r.success }.to_s,
        total_time: "#{total_time.total_milliseconds}ms")

      log_compression_stats
      @results
    end

    def process_single_asset(asset_path : String, is_theme_asset : Bool = false) : AssetResult
      # Validate asset path exists
      unless File.exists?(asset_path)
        Logger.error("Asset file not found", path: asset_path)
        return AssetResult.new(asset_path, "", AssetType::Other, 0, 0, Time::Span.zero, false, "File not found")
      end

      unless File.file?(asset_path)
        Logger.error("Asset path is not a file", path: asset_path)
        return AssetResult.new(asset_path, "", AssetType::Other, 0, 0, Time::Span.zero, false, "Path is not a file")
      end

      asset_info = AssetInfo.new(asset_path, is_theme_asset)
      process_asset(asset_info)
    end

    private def discover_all_assets : Array(AssetInfo)
      assets = [] of AssetInfo

      # Discover theme assets first (base layer)
      theme_static_dir = Path[@config.theme_dir].join("static").to_s
      if Dir.exists?(theme_static_dir)
        Logger.debug("Discovering theme assets", path: theme_static_dir)
        Dir.glob(Path[theme_static_dir].join("**/*").to_s).each do |file_path|
          next unless File.file?(file_path)
          assets << AssetInfo.new(file_path, true)
          Logger.debug("Found theme asset", path: file_path)
        end
      end

      # Discover site assets (override layer)
      if Dir.exists?(@config.static_dir)
        Logger.debug("Discovering site assets", path: @config.static_dir)
        Dir.glob(Path[@config.static_dir].join("**/*").to_s).each do |file_path|
          next unless File.file?(file_path)
          assets << AssetInfo.new(file_path, false)
          Logger.debug("Found site asset", path: file_path)
        end
      end

      # Remove duplicates (site assets override theme assets)
      assets = remove_duplicate_assets(assets)
      Logger.debug("Total unique assets discovered", count: assets.size.to_s)
      assets
    end

    private def remove_duplicate_assets(assets : Array(AssetInfo)) : Array(AssetInfo)
      # Group by relative path, preferring site assets over theme assets
      grouped = assets.group_by(&.relative_path)

      grouped.map do |relative_path, asset_group|
        # If multiple assets have the same relative path, prefer site asset
        site_assets = asset_group.select { |a| !a.is_theme_asset }
        site_assets.any? ? site_assets.first : asset_group.first
      end
    end

    private def process_assets_by_type(assets : Array(AssetInfo))
      # Process assets by type
      process_assets(assets.select { |a| a.type == AssetType::CSS })
      process_assets(assets.select { |a| a.type == AssetType::JavaScript })
      process_assets(assets.select { |a| a.type == AssetType::Image })
      process_assets(assets.select { |a| a.type == AssetType::Font })
      process_assets(assets.select { |a| a.type == AssetType::Other })
    end

    private def process_assets(assets : Array(AssetInfo))
      return if assets.empty?

      Logger.info("Processing #{assets.size} #{assets.first.type} assets")

      assets.each do |asset|
        result = process_asset(asset)
        @results << result

        # Check if results collection is getting too large
        if @results.size > @max_results_size
          Logger.warn("Asset results collection too large, clearing old entries",
            current_size: @results.size,
            max_size: @max_results_size)
          # Keep only the most recent results
          @results = @results.last((@max_results_size / 2).to_i)
        end
      end
    end

    private def process_asset(asset : AssetInfo) : AssetResult
      start_time = Time.monotonic
      original_size = File.size(asset.path)

      begin
        # Generate output path
        output_path = generate_output_path(asset)

        # Create output directory
        Dir.mkdir_p(Path[output_path].parent.to_s)

        # Process based on asset type
        case asset.type
        when .css?
          process_css_asset(asset, output_path)
        when .java_script?
          process_js_asset(asset, output_path)
        when .image?
          process_image_asset(asset, output_path)
        when .font?
          process_font_asset(asset, output_path)
        else
          process_other_asset(asset, output_path)
        end

        processed_size = File.size(output_path)
        processing_time = Time.monotonic - start_time

        Logger.debug("Processed asset",
          source: asset.path,
          output: output_path,
          type: asset.type.to_s,
          size_before: "#{(original_size / 1024.0).round(1)}KB",
          size_after: "#{(processed_size / 1024.0).round(1)}KB")

        AssetResult.new(asset.path, output_path, asset.type,
          original_size, processed_size, processing_time, true)
      rescue ex
        processing_time = Time.monotonic - start_time
        Logger.error("Failed to process asset", file: asset.path, error: ex.message)

        AssetResult.new(asset.path, "", asset.type,
          original_size, 0, processing_time, false, ex.message)
      end
    end

    private def generate_output_path(asset : AssetInfo) : String
      # Simple output structure: assets/{relative_path}
      Path[@config.output_dir].join("assets", asset.relative_path).to_s
    end

    # Asset type processors
    private def process_css_asset(asset : AssetInfo, output_path : String)
      # Stream-based processing for better memory efficiency
      File.open(asset.path, "r") do |input|
        File.open(output_path, "w") do |output|
          # For small CSS files, read and process
          if File.info(asset.path).size < 1024 * 1024 # 1MB
            css_content = input.gets_to_end
            processed_css = process_css_content(css_content)
            output.print(processed_css)
          else
            # For large files, stream line by line
            input.each_line do |line|
              processed_line = process_css_content(line)
              output.puts(processed_line)
            end
          end
        end
      end
    rescue ex : File::NotFoundError
      raise "CSS file not found: #{asset.path}"
    rescue ex : IO::Error
      raise "Error reading CSS file #{asset.path}: #{ex.message}"
    rescue ex
      raise "Error processing CSS file #{asset.path}: #{ex.message}"
    end

    private def process_js_asset(asset : AssetInfo, output_path : String)
      # Stream-based processing for better memory efficiency
      File.open(asset.path, "r") do |input|
        File.open(output_path, "w") do |output|
          # For small JS files, read and process
          if File.info(asset.path).size < 1024 * 1024 # 1MB
            js_content = input.gets_to_end
            processed_js = process_js_content(js_content)
            output.print(processed_js)
          else
            # For large files, stream line by line to avoid memory issues
            input.each_line do |line|
              processed_line = process_js_content(line)
              output.puts(processed_line)
            end
          end
        end
      end
    rescue ex : File::NotFoundError
      raise "JavaScript file not found: #{asset.path}"
    rescue ex : IO::Error
      raise "Error reading JavaScript file #{asset.path}: #{ex.message}"
    rescue ex
      raise "Error processing JavaScript file #{asset.path}: #{ex.message}"
    end

    private def process_image_asset(asset : AssetInfo, output_path : String)
      # For now, just copy images
      # TODO: Add image optimization
      File.copy(asset.path, output_path)
    rescue ex : File::NotFoundError
      raise "Image file not found: #{asset.path}"
    rescue ex : IO::Error
      raise "Error copying image file #{asset.path}: #{ex.message}"
    rescue ex
      raise "Error processing image file #{asset.path}: #{ex.message}"
    end

    private def process_font_asset(asset : AssetInfo, output_path : String)
      # Copy fonts as-is
      File.copy(asset.path, output_path)
    rescue ex : File::NotFoundError
      raise "Font file not found: #{asset.path}"
    rescue ex : IO::Error
      raise "Error copying font file #{asset.path}: #{ex.message}"
    rescue ex
      raise "Error processing font file #{asset.path}: #{ex.message}"
    end

    private def process_other_asset(asset : AssetInfo, output_path : String)
      # Copy other files as-is
      File.copy(asset.path, output_path)
    rescue ex : File::NotFoundError
      raise "Asset file not found: #{asset.path}"
    rescue ex : IO::Error
      raise "Error copying asset file #{asset.path}: #{ex.message}"
    rescue ex
      raise "Error processing asset file #{asset.path}: #{ex.message}"
    end

    # Content processors
    private def process_css_content(css_content : String) : String
      # Optimized CSS processing with non-greedy patterns
      # Use String.build to avoid multiple temporary string allocations
      String.build do |str|
        # Remove comments with non-greedy pattern to avoid stack overflow
        processed = css_content.gsub(/\/\*[^*]*\*+(?:[^\/\*][^*]*\*+)*\//, "")

        # Minify whitespace efficiently in a single pass
        in_whitespace = false
        in_brace = false
        in_semicolon = false

        processed.each_char do |char|
          case char
          when ' ', '\t', '\n', '\r'
            unless in_whitespace
              str << ' '
              in_whitespace = true
            end
          when '{'
            str << '{'
            in_brace = true
            in_whitespace = false
          when '}'
            str << '}'
            in_brace = false
            in_whitespace = false
          when ';'
            str << ';'
            in_semicolon = true
            in_whitespace = false
          else
            str << char
            in_whitespace = false
            in_semicolon = false
          end
        end
      end.strip
    end

    private def process_js_content(js_content : String) : String
      # Basic JS minification - remove comments and extra whitespace
      processed = js_content

      # Remove single-line comments (but not URLs with //)
      processed = processed.gsub(/\/\/(?![\/\s]).*$/, "")

      # Remove multi-line comments (but be careful with large blocks)
      processed = processed.gsub(/\/\*[^*]*\*+(?:[^\/\*][^*]*\*+)*\//, "")

      # Minify whitespace
      processed = processed.gsub(/\s+/, " ").strip

      processed
    end

    # Cache management with size limits
    private def load_asset_cache
      cache_file = Path[@cache_dir].join("asset_cache.json").to_s
      return unless File.exists?(cache_file)

      begin
        # TODO: Implement proper JSON cache loading
        @asset_cache = {} of String => String
      rescue ex
        Logger.warn("Failed to load asset cache", error: ex.message)
        @asset_cache = {} of String => String
      end
    end

    private def save_asset_cache
      cache_file = Path[@cache_dir].join("asset_cache.json").to_s
      begin
        # TODO: Implement proper JSON cache saving
        Logger.debug("Asset cache saved", file: cache_file)
      rescue ex
        Logger.warn("Failed to save asset cache", error: ex.message)
      end
    end

    # Safe cache addition with size limits
    private def add_to_asset_cache(key : String, value : String)
      memory_manager = Lapis.memory_manager
      memory_manager.add_to_cache_safely(@asset_cache, key, value, @max_cache_size)
    end

    # Cleanup method for memory management
    def cleanup
      Logger.debug("Cleaning up UnifiedAssetProcessor")

      # Clear large collections
      if @results.size > 1000
        Logger.info("Clearing large results collection", size: @results.size)
        @results.clear
      end

      # Clear cache if it's too large
      if @asset_cache.size > @max_cache_size
        Logger.info("Clearing large asset cache", size: @asset_cache.size)
        @asset_cache.clear
      end

      # Force GC if needed
      memory_manager = Lapis.memory_manager
      memory_manager.periodic_cleanup
    end

    private def log_compression_stats
      total_before = @results.sum(&.size_before)
      total_after = @results.sum(&.size_after)
      space_saved = total_before - total_after
      compression_ratio = total_before > 0 ? (space_saved.to_f / total_before.to_f * 100.0) : 0.0

      Logger.info("Asset compression summary",
        total_size_before: "#{(total_before / 1024.0).round(1)}KB",
        total_size_after: "#{(total_after / 1024.0).round(1)}KB",
        space_saved: "#{(space_saved / 1024.0).round(1)}KB",
        compression_ratio: "#{compression_ratio.round(1)}%")
    end
  end
end
