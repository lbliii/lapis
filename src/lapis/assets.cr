require "digest/md5"

module Lapis
  class AssetProcessor
    property config : Config
    property source_dir : String
    property output_dir : String

    def initialize(@config : Config)
      @source_dir = @config.static_dir
      @output_dir = File.join(@config.output_dir, "assets")
    end

    def process_all_assets
      Dir.mkdir_p(@output_dir)
      processed_count = 0

      # Process theme assets first (base layer)
      theme_static_dir = File.join(@config.theme_dir, "static")
      if Dir.exists?(theme_static_dir)
        Dir.glob(File.join(theme_static_dir, "**", "*")).each do |file_path|
          next unless File.file?(file_path)

          relative_path = file_path[theme_static_dir.size + 1..]

          if image_file?(file_path)
            process_image(file_path, relative_path)
            processed_count += 1
          else
            copy_asset(file_path, relative_path)
          end
        end
      end

      # Process site assets (override layer)
      if Dir.exists?(@source_dir)
        Dir.glob(File.join(@source_dir, "**", "*")).each do |file_path|
          next unless File.file?(file_path)

          relative_path = file_path[@source_dir.size + 1..]

          if image_file?(file_path)
            process_image(file_path, relative_path)
            processed_count += 1
          else
            copy_asset(file_path, relative_path)
          end
        end
      end

      puts "  Processed #{processed_count} images with optimization"
    end

    private def image_file?(file_path : String) : Bool
      ext = File.extname(file_path).downcase
      [".jpg", ".jpeg", ".png", ".gif", ".svg", ".webp"].includes?(ext)
    end

    private def process_image(source_path : String, relative_path : String)
      output_path = File.join(@output_dir, relative_path)
      output_dir = File.dirname(output_path)
      Dir.mkdir_p(output_dir)

      # For now, just copy the image - we'll add real optimization later
      # This is a placeholder for the image optimization pipeline
      File.copy(source_path, output_path)

      # Generate responsive versions if it's a large image
      generate_responsive_images(source_path, relative_path)
    end

    private def generate_responsive_images(source_path : String, relative_path : String)
      # Placeholder for responsive image generation
      # In a real implementation, this would:
      # 1. Read image dimensions
      # 2. Generate multiple sizes (320w, 640w, 1024w, 1920w)
      # 3. Convert to WebP format
      # 4. Create srcset metadata

      base_name = File.basename(relative_path, File.extname(relative_path))
      ext = File.extname(relative_path)
      dir = File.dirname(relative_path)

      sizes = [320, 640, 1024, 1920]

      sizes.each do |width|
        # Generate filename: image-320w.jpg, image-640w.jpg, etc.
        responsive_name = "#{base_name}-#{width}w#{ext}"
        responsive_path = File.join(dir, responsive_name)
        output_path = File.join(@output_dir, responsive_path)

        # For now, just copy the original - later we'll add real resizing
        File.copy(source_path, output_path)
      end

      # Also generate WebP version
      webp_name = "#{base_name}.webp"
      webp_path = File.join(dir, webp_name)
      webp_output = File.join(@output_dir, webp_path)
      File.copy(source_path, webp_output)
    end

    private def copy_asset(source_path : String, relative_path : String)
      output_path = File.join(@output_dir, relative_path)
      output_dir = File.dirname(output_path)
      Dir.mkdir_p(output_dir)
      File.copy(source_path, output_path)
    end

    def generate_asset_manifest : Hash(String, AssetInfo)
      manifest = Hash(String, AssetInfo).new

      return manifest unless Dir.exists?(@output_dir)

      Dir.glob(File.join(@output_dir, "**", "*")).each do |file_path|
        next unless File.file?(file_path)

        relative_path = file_path[@output_dir.size + 1..]
        url = "/assets/#{relative_path}"

        file_info = File.info(file_path)
        content_hash = calculate_file_hash(file_path)

        manifest[relative_path] = AssetInfo.new(
          url: url,
          size: file_info.size,
          hash: content_hash,
          modified: file_info.modification_time
        )
      end

      manifest
    end

    private def calculate_file_hash(file_path : String) : String
      Digest::MD5.hexdigest(File.read(file_path))
    end
  end

  class AssetInfo
    property url : String
    property size : Int64
    property hash : String
    property modified : Time

    def initialize(@url : String, @size : Int64, @hash : String, @modified : Time)
    end

    def cache_busted_url : String
      "#{@url}?v=#{@hash[0..7]}"
    end
  end

  class ImageOptimizer
    def self.optimize(source_path : String, output_path : String, options = {} of String => String)
      # Placeholder for actual image optimization
      # This would integrate with image processing libraries like:
      # - ImageMagick (via bindings)
      # - libvips (for high performance)
      # - or shell out to external tools like squoosh-cli

      File.copy(source_path, output_path)
    end

    def self.generate_webp(source_path : String, output_path : String)
      # Placeholder for WebP generation
      File.copy(source_path, output_path)
    end

    def self.resize(source_path : String, output_path : String, width : Int32)
      # Placeholder for image resizing
      File.copy(source_path, output_path)
    end
  end

  # Helper methods for templates
  module AssetHelpers
    def asset_url(path : String, manifest : Hash(String, AssetInfo)? = nil) : String
      if manifest
        if asset_info = manifest[path]?
          return asset_info.cache_busted_url
        end
      end
      "/assets/#{path}"
    end

    def responsive_image_tag(src : String, alt : String = "", class_name : String = "") : String
      base_name = File.basename(src, File.extname(src))
      ext = File.extname(src)
      dir = File.dirname(src) == "." ? "" : "#{File.dirname(src)}/"

      # Generate srcset
      sizes = [320, 640, 1024, 1920]
      srcset_items = sizes.map do |width|
        "#{asset_url("#{dir}#{base_name}-#{width}w#{ext}")} #{width}w"
      end

      srcset = srcset_items.join(", ")
      webp_src = asset_url("#{dir}#{base_name}.webp")

      <<-HTML
      <picture>
        <source srcset="#{webp_src}" type="image/webp">
        <img src="#{asset_url(src)}"
             srcset="#{srcset}"
             sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 25vw"
             alt="#{alt}"
             class="#{class_name}"
             loading="lazy">
      </picture>
      HTML
    end
  end
end