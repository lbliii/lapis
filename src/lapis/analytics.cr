module Lapis
  class BuildAnalytics
    property start_time : Time
    property end_time : Time?
    property content_stats : Hash(String, Int32)
    property asset_stats : Hash(String, Int32)
    property timing_stats : Hash(String, Float64)
    property file_sizes : Hash(String, Int64)

    def initialize
      @start_time = Time.utc
      @end_time = nil
      @content_stats = Hash(String, Int32).new(0)
      @asset_stats = Hash(String, Int32).new(0)
      @timing_stats = Hash(String, Float64).new(0.0)
      @file_sizes = Hash(String, Int64).new(0)
    end

    def start_build
      @start_time = Time.utc
      puts "🚀 Starting build at #{@start_time.to_s("%H:%M:%S")}"
    end

    def finish_build
      @end_time = Time.utc
      total_time = build_duration
      puts "✅ Build completed in #{format_duration(total_time)}"
    end

    def build_duration : Float64
      end_time = @end_time || Time.utc
      (end_time - @start_time).total_seconds
    end

    def time_operation(name : String, &)
      start = Time.utc
      result = yield
      duration = (Time.utc - start).total_seconds
      @timing_stats[name] = duration
      puts "  #{name} completed in #{format_duration(duration)}"
      result
    end

    def track_content(type : String, count : Int32 = 1)
      @content_stats[type] += count
    end

    def track_asset(type : String, count : Int32 = 1)
      @asset_stats[type] += count
    end

    def track_file_size(path : String, size : Int64)
      @file_sizes[path] = size
    end

    def generate_report : String
      total_time = build_duration

      content_summary = @content_stats.map { |type, count| "#{count} #{type}" }.join(", ")
      asset_summary = @asset_stats.map { |type, count| "#{count} #{type}" }.join(", ")

      total_output_size = @file_sizes.values.sum
      largest_files = @file_sizes.to_a.sort_by(&.[1]).reverse.first(5)

      performance_insights = generate_performance_insights

      report = <<-REPORT

      📊 Build Analytics Report
      ═══════════════════════════════════════

      ⏱️  Total Build Time: #{format_duration(total_time)}
      📝 Content Generated: #{content_summary}
      🎨 Assets Processed: #{asset_summary}
      💾 Total Output Size: #{format_file_size(total_output_size)}

      ⚡ Performance Breakdown:
      #{format_timing_breakdown}

      📁 Largest Files:
      #{format_largest_files(largest_files)}

      💡 Performance Insights:
      #{performance_insights}

      REPORT

      report
    end

    private def format_duration(seconds : Float64) : String
      if seconds < 1.0
        "#{(seconds * 1000).round(1)}ms"
      elsif seconds < 60.0
        "#{seconds.round(2)}s"
      else
        minutes = (seconds / 60).floor.to_i
        remaining_seconds = seconds % 60
        "#{minutes}m #{remaining_seconds.round(1)}s"
      end
    end

    private def format_file_size(bytes : Int64) : String
      if bytes < 1024
        "#{bytes}B"
      elsif bytes < 1024 * 1024
        "#{(bytes / 1024.0).round(1)}KB"
      elsif bytes < 1024 * 1024 * 1024
        "#{(bytes / (1024.0 * 1024.0)).round(1)}MB"
      else
        "#{(bytes / (1024.0 * 1024.0 * 1024.0)).round(1)}GB"
      end
    end

    private def format_timing_breakdown : String
      @timing_stats.map do |operation, duration|
        percentage = (duration / build_duration * 100).round(1)
        "     #{operation.ljust(25)} #{format_duration(duration).rjust(8)} (#{percentage}%)"
      end.join("\n")
    end

    private def format_largest_files(files : Array(Tuple(String, Int64))) : String
      files.map do |path, size|
        "     #{File.basename(path).ljust(30)} #{format_file_size(size).rjust(10)}"
      end.join("\n")
    end

    private def generate_performance_insights : String
      insights = [] of String

      # Build time insights
      total_time = build_duration
      if total_time > 10.0
        insights << "🐌 Build time is over 10 seconds. Consider optimizing asset processing."
      elsif total_time < 1.0
        insights << "🚀 Excellent build performance! Under 1 second."
      end

      # Content insights
      total_content = @content_stats.values.sum
      if total_content > 1000
        insights << "📚 Large site detected (#{total_content} pages). Consider implementing incremental builds."
      end

      # Asset insights
      total_assets = @asset_stats.values.sum
      if total_assets > 100
        insights << "🎨 Many assets detected (#{total_assets}). Image optimization is recommended."
      end

      # File size insights
      total_size = @file_sizes.values.sum
      if total_size > 100 * 1024 * 1024 # 100MB
        insights << "💾 Large output size (#{format_file_size(total_size)}). Consider asset compression."
      end

      # Timing insights
      if content_time = @timing_stats["Content Processing"]?
        if asset_time = @timing_stats["Asset Processing"]?
          if asset_time > content_time * 2
            insights << "⚡ Asset processing is slow compared to content. Consider parallel processing."
          end
        end
      end

      insights.empty? ? "     All metrics look good! 👍" : insights.map { |i| "     #{i}" }.join("\n")
    end
  end

  class PerformanceProfiler
    property operations : Hash(String, Array(Float64))

    def initialize
      @operations = Hash(String, Array(Float64)).new { |h, k| h[k] = [] of Float64 }
    end

    def profile(operation : String, &)
      start_time = Time.utc
      result = yield
      duration = (Time.utc - start_time).total_seconds
      @operations[operation] << duration
      result
    end

    def stats_for(operation : String) : NamedTuple(count: Int32, total: Float64, average: Float64, min: Float64, max: Float64)
      times = @operations[operation]
      return {count: 0, total: 0.0, average: 0.0, min: 0.0, max: 0.0} if times.empty?

      {
        count:   times.size,
        total:   times.sum,
        average: times.sum / times.size,
        min:     times.min,
        max:     times.max,
      }
    end

    def report : String
      return "No operations profiled." if @operations.empty?

      lines = ["Performance Profile:"]
      @operations.each do |operation, times|
        stats = stats_for(operation)
        lines << "  #{operation}: #{stats[:count]} calls, avg #{(stats[:average] * 1000).round(1)}ms"
      end

      lines.join("\n")
    end
  end

  # Extension methods for Generator analytics
  module GeneratorAnalytics
    def build_with_analytics
      analytics = BuildAnalytics.new
      analytics.start_build

      analytics.time_operation("Clean & Setup") do
        clean_output_directory
        create_output_directory
      end

      all_content = analytics.time_operation("Content Loading") do
        load_all_content
      end

      analytics.time_operation("Content Processing") do
        Logger.info("Build strategy decision",
          incremental: @config.build_config.incremental,
          parallel: @config.build_config.parallel)

        if @config.build_config.incremental
          Logger.info("Using incremental build strategy")
          generate_content_pages_incremental_v2(all_content)
        else
          Logger.info("Using regular build strategy")
          generate_content_pages(all_content)
        end
        analytics.track_content("pages", all_content.size)
      end

      analytics.time_operation("Asset Processing") do
        Logger.info("Starting asset processing")
        @asset_processor.process_all_assets
        Logger.info("Asset processing completed")
        # Track asset counts would be added here
      end

      analytics.time_operation("Archive Generation") do
        Logger.info("Starting archive generation")
        generate_index_page(all_content)
        Logger.debug("Index page generated")
        generate_archive_pages(all_content)
        Logger.debug("Archive pages generated")
        Logger.info("Archive generation completed")
      end

      analytics.time_operation("Feed Generation") do
        Logger.info("Starting feed generation")
        generate_feeds(all_content)
        Logger.info("Feed generation completed")
        # generate_sitemap(all_content) # TODO: Implement sitemap generator
      end

      # Calculate output file sizes
      Logger.info("Calculating output file sizes")
      calculate_output_sizes(analytics)

      Logger.info("Finishing build analytics")
      analytics.finish_build

      # Print analytics report
      Logger.info("Generating analytics report")
      puts analytics.generate_report
      Logger.info("Build completed successfully")
    end

    private def calculate_output_sizes(analytics : BuildAnalytics)
      return unless Dir.exists?(@config.output_dir)

      Dir.glob(File.join(@config.output_dir, "**", "*")).each do |file_path|
        if File.file?(file_path)
          size = File.info(file_path).size
          relative_path = file_path[@config.output_dir.size + 1..]
          analytics.track_file_size(relative_path, size)
        end
      end
    end
  end
end
