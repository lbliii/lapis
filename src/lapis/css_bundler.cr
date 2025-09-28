require "file_utils"
require "log"
require "./logger"

module Lapis
  # CSS Bundle configuration
  class CSSBundleConfig
    include YAML::Serializable

    property bundles : Array(CSSBundle) = [] of CSSBundle
    property minify : Bool = true
    property autoprefix : Bool = false
    property source_maps : Bool = false

    def initialize
    end
  end

  # Individual CSS bundle
  class CSSBundle
    include YAML::Serializable

    property name : String
    property files : Array(String)
    property output : String
    property order : Int32 = 0

    def initialize(@name : String, @files : Array(String), @output : String, @order = 0)
    end
  end

  # CSS Bundler for combining and optimizing CSS files
  class CSSBundler
    property config : CSSBundleConfig
    property bundles : Array(CSSBundle) = [] of CSSBundle

    def initialize(@config : CSSBundleConfig)
      @bundles = @config.bundles.sort_by(&.order)
    end

    def bundle_all(output_dir : String) : Array(BundleResult)
      results = [] of BundleResult

      @bundles.each do |bundle|
        result = bundle_css(bundle, output_dir)
        results << result
      end

      results
    end

    def bundle_css(bundle : CSSBundle, output_dir : String) : BundleResult
      start_time = Time.monotonic

      begin
        # Read and combine CSS files
        combined_css = read_and_combine_css(bundle.files)

        # Process CSS
        processed_css = process_css(combined_css)

        # Generate output path
        output_path = File.join(output_dir, bundle.output)

        # Create output directory
        Dir.mkdir_p(File.dirname(output_path))

        # Write bundled CSS
        File.write(output_path, processed_css)

        # Generate source map if enabled
        if @config.source_maps
          generate_source_map(bundle, output_path, processed_css)
        end

        # Generate compressed version
        generate_compressed_version(output_path)

        processing_time = Time.monotonic - start_time

        Logger.info("CSS bundle created",
          name: bundle.name,
          output: output_path,
          files: bundle.files.size.to_s,
          size: "#{(File.size(output_path) / 1024.0).round(1)}KB")

        BundleResult.new(bundle.name, output_path, true, processing_time, nil)
      rescue ex
        processing_time = Time.monotonic - start_time
        Logger.error("Failed to bundle CSS", bundle: bundle.name, error: ex.message)

        BundleResult.new(bundle.name, "", false, processing_time, ex.message)
      end
    end

    private def read_and_combine_css(file_paths : Array(String)) : String
      combined = [] of String

      file_paths.each do |file_path|
        if File.exists?(file_path)
          css_content = File.read(file_path)

          # Add file header comment
          combined << "/* #{file_path} */"
          combined << css_content
          combined << ""
        else
          Logger.warn("CSS file not found", file: file_path)
        end
      end

      combined.join("\n")
    end

    private def process_css(css_content : String) : String
      processed = css_content

      # Remove comments if minifying
      if @config.minify
        processed = remove_css_comments(processed)
      end

      # Minify whitespace if minifying
      if @config.minify
        processed = minify_css_whitespace(processed)
      end

      # Optimize colors
      processed = optimize_css_colors(processed)

      # Remove unnecessary semicolons
      processed = remove_unnecessary_semicolons(processed)

      # TODO: Add autoprefixing if enabled
      if @config.autoprefix
        processed = add_vendor_prefixes(processed)
      end

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

    private def optimize_css_colors(css : String) : String
      # Convert #ffffff to #fff, etc.
      css.gsub(/#([0-9a-fA-F])\1([0-9a-fA-F])\2([0-9a-fA-F])\3/, "#\\1\\2\\3")
    end

    private def remove_unnecessary_semicolons(css : String) : String
      css.gsub(/;}/, "}")
    end

    private def add_vendor_prefixes(css : String) : String
      # Simple vendor prefixing for common properties
      # In a real implementation, this would use a proper autoprefixer

      # Flexbox properties
      css = css.gsub(/display:\s*flex/, "display: -webkit-box; display: -ms-flexbox; display: flex")
      css = css.gsub(/flex:\s*(\d+(?:\.\d+)?)/, "-webkit-box-flex: \\1; -ms-flex: \\1; flex: \\1")

      # Transform properties
      css = css.gsub(/transform:\s*([^;]+)/, "-webkit-transform: \\1; -ms-transform: \\1; transform: \\1")

      css
    end

    private def generate_source_map(bundle : CSSBundle, output_path : String, css_content : String)
      # Generate basic source map
      source_map = {
        version:  3,
        sources:  bundle.files,
        names:    [] of String,
        mappings: "AAAA", # Simplified mapping
        file:     File.basename(output_path),
      }.to_json

      source_map_path = "#{output_path}.map"
      File.write(source_map_path, source_map)

      # Add source map reference to CSS
      css_with_map = css_content + "\n/*# sourceMappingURL=#{File.basename(source_map_path)} */"
      File.write(output_path, css_with_map)
    end

    private def generate_compressed_version(output_path : String)
      compressed_path = "#{output_path}.gz"

      File.open(output_path, "r") do |input|
        File.open(compressed_path, "w") do |output|
          Compress::Gzip::Writer.open(output) do |gzip|
            IO.copy(input, gzip)
          end
        end
      end
    end
  end

  # Bundle result
  struct BundleResult
    property bundle_name : String
    property output_path : String
    property success : Bool
    property processing_time : Time::Span
    property error : String?

    def initialize(@bundle_name : String, @output_path : String, @success : Bool,
                   @processing_time : Time::Span, @error : String? = nil)
    end
  end
end
