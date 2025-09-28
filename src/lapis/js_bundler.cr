require "file_utils"
require "log"
require "./logger"

module Lapis
  # JavaScript Bundle configuration
  class JSBundleConfig
    include YAML::Serializable

    property bundles : Array(JSBundle) = [] of JSBundle
    property minify : Bool = true
    property tree_shake : Bool = false
    property source_maps : Bool = false
    property target : String = "es2015"

    def initialize
    end
  end

  # Individual JavaScript bundle
  class JSBundle
    include YAML::Serializable

    property name : String
    property files : Array(String)
    property output : String
    property order : Int32 = 0
    property type : String = "application/javascript"

    def initialize(@name : String, @files : Array(String), @output : String, @order = 0, @type = "application/javascript")
    end
  end

  # JavaScript Bundler for combining and optimizing JS files
  class JSBundler
    property config : JSBundleConfig
    property bundles : Array(JSBundle) = [] of JSBundle

    def initialize(@config : JSBundleConfig)
      @bundles = @config.bundles.sort_by(&.order)
    end

    def bundle_all(output_dir : String) : Array(BundleResult)
      results = [] of BundleResult

      @bundles.each do |bundle|
        result = bundle_js(bundle, output_dir)
        results << result
      end

      results
    end

    def bundle_js(bundle : JSBundle, output_dir : String) : BundleResult
      start_time = Time.monotonic

      begin
        # Read and combine JavaScript files
        combined_js = read_and_combine_js(bundle.files)

        # Process JavaScript
        processed_js = process_js(combined_js)

        # Generate output path
        output_path = File.join(output_dir, bundle.output)

        # Create output directory
        Dir.mkdir_p(File.dirname(output_path))

        # Write bundled JavaScript
        File.write(output_path, processed_js)

        # Generate source map if enabled
        if @config.source_maps
          generate_source_map(bundle, output_path, processed_js)
        end

        # Generate compressed version
        generate_compressed_version(output_path)

        processing_time = Time.monotonic - start_time

        Logger.info("JavaScript bundle created",
          name: bundle.name,
          output: output_path,
          files: bundle.files.size.to_s,
          size: "#{(File.size(output_path) / 1024.0).round(1)}KB")

        BundleResult.new(bundle.name, output_path, true, processing_time, nil)
      rescue ex
        processing_time = Time.monotonic - start_time
        Logger.error("Failed to bundle JavaScript", bundle: bundle.name, error: ex.message)

        BundleResult.new(bundle.name, "", false, processing_time, ex.message)
      end
    end

    private def read_and_combine_js(file_paths : Array(String)) : String
      combined = [] of String

      file_paths.each do |file_path|
        if File.exists?(file_path)
          js_content = File.read(file_path)

          # Add file header comment
          combined << "/* #{file_path} */"
          combined << js_content
          combined << ""
        else
          Logger.warn("JavaScript file not found", file: file_path)
        end
      end

      combined.join("\n")
    end

    private def process_js(js_content : String) : String
      processed = js_content

      # Remove comments if minifying
      if @config.minify
        processed = remove_js_comments(processed)
      end

      # Minify whitespace if minifying
      if @config.minify
        processed = minify_js_whitespace(processed)
      end

      # Remove unnecessary semicolons
      processed = remove_unnecessary_semicolons(processed)

      # Optimize variables and functions
      if @config.minify
        processed = optimize_js_variables(processed)
      end

      # TODO: Add tree shaking if enabled
      if @config.tree_shake
        processed = tree_shake_js(processed)
      end

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
        .gsub(/\s*,\s*/m, ",")
        .strip
    end

    private def remove_unnecessary_semicolons(js : String) : String
      js.gsub(/;}/, "}")
    end

    private def optimize_js_variables(js : String) : String
      # Simple variable optimization (in a real implementation, this would be more sophisticated)

      # Remove unnecessary spaces around operators
      js = js.gsub(/\s*=\s*/, "=")
      js = js.gsub(/\s*\+\s*/, "+")
      js = js.gsub(/\s*-\s*/, "-")
      js = js.gsub(/\s*\*\s*/, "*")
      js = js.gsub(/\s*\/\s*/, "/")

      js
    end

    private def tree_shake_js(js : String) : String
      # Simple tree shaking (in a real implementation, this would analyze imports/exports)
      # For now, just return the original content
      Logger.debug("Tree shaking not yet implemented")
      js
    end

    private def generate_source_map(bundle : JSBundle, output_path : String, js_content : String)
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

      # Add source map reference to JavaScript
      js_with_map = js_content + "\n//# sourceMappingURL=#{File.basename(source_map_path)}"
      File.write(output_path, js_with_map)
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

  # Bundle result (reusing from CSS bundler)
  alias JSBundleResult = BundleResult
end
