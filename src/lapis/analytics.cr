require "colorize"

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
      puts "🚀 Starting build at #{@start_time.to_s("%H:%M:%S")}".colorize(:green).bold
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

      # SLICE-BASED FILE SIZE PROCESSING FOR ZERO-COPY OPERATIONS
      # For now, use regular array operations - slice ops need more work
      total_output_size_slice = @file_sizes.values.sum

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

    # Pre-computed tuple for common performance metrics
    private PERFORMANCE_METRICS = {
      :count, :total, :average, :min, :max, :median, :p95, :p99,
    }

    # Tuple for operation categories
    private OPERATION_CATEGORIES = {
      :build, :template, :content, :asset, :cache, :network,
    }

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

      # Use tuple operations for efficient computation
      stats_tuple = compute_stats_tuple(times)

      {
        count:   stats_tuple[0],
        total:   stats_tuple[1],
        average: stats_tuple[2],
        min:     stats_tuple[3],
        max:     stats_tuple[4],
      }
    end

    # SLICE-BASED STATS FOR ZERO-COPY OPERATIONS
    def stats_for_slice(operation : String) : NamedTuple(count: Int32, total: Float64, average: Float64, min: Float64, max: Float64)
      times = @operations[operation]
      return {count: 0, total: 0.0, average: 0.0, min: 0.0, max: 0.0} if times.empty?

      # Convert to slice for zero-copy operations
      times_slice = times.to_slice
      compute_stats_from_slice(times_slice)
    end

    # Tuple-based stats computation using tuple operations
    private def compute_stats_tuple(times : Array(Float64)) : Tuple(Int32, Float64, Float64, Float64, Float64)
      return {0, 0.0, 0.0, 0.0, 0.0} if times.empty?

      # Use tuple operations for efficient computation
      count = times.size
      total = times.sum
      average = total / count

      # Use tuple to_a and sorting for min/max
      sorted_times = times.to_a.sort
      min = sorted_times.first
      max = sorted_times.last

      {count, total, average, min, max}
    end

    # SLICE-BASED STATS COMPUTATION FOR ZERO-COPY OPERATIONS
    private def compute_stats_from_slice(times_slice : Slice(Float64)) : NamedTuple(count: Int32, total: Float64, average: Float64, min: Float64, max: Float64)
      return {count: 0, total: 0.0, average: 0.0, min: 0.0, max: 0.0} if times_slice.empty?

      count = times_slice.size
      total = times_slice.sum
      average = total / count

      # Use Slice operations for min/max - more efficient than sorting
      min = times_slice.min
      max = times_slice.max

      {count: count, total: total, average: average, min: min, max: max}
    end

    # Enhanced stats with tuple-based percentile calculations
    def enhanced_stats_for(operation : String) : NamedTuple(count: Int32, total: Float64, average: Float64, min: Float64, max: Float64, median: Float64, p95: Float64, p99: Float64)
      times = @operations[operation]
      return {count: 0, total: 0.0, average: 0.0, min: 0.0, max: 0.0, median: 0.0, p95: 0.0, p99: 0.0} if times.empty?

      # Use tuple operations for efficient computation
      enhanced_tuple = compute_enhanced_stats_tuple(times)

      {
        count:   enhanced_tuple[0],
        total:   enhanced_tuple[1],
        average: enhanced_tuple[2],
        min:     enhanced_tuple[3],
        max:     enhanced_tuple[4],
        median:  enhanced_tuple[5],
        p95:     enhanced_tuple[6],
        p99:     enhanced_tuple[7],
      }
    end

    private def compute_enhanced_stats_tuple(times : Array(Float64)) : Tuple(Int32, Float64, Float64, Float64, Float64, Float64, Float64, Float64)
      return {0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0} if times.empty?

      count = times.size
      total = times.sum
      average = total / count

      # Use tuple operations for sorting and percentile calculation
      sorted_times = times.to_a.sort
      min = sorted_times.first
      max = sorted_times.last

      # Calculate percentiles using tuple operations
      median = calculate_percentile_tuple(sorted_times, 50)
      p95 = calculate_percentile_tuple(sorted_times, 95)
      p99 = calculate_percentile_tuple(sorted_times, 99)

      {count, total, average, min, max, median, p95, p99}
    end

    private def calculate_percentile_tuple(sorted_times : Array(Float64), percentile : Int32) : Float64
      return 0.0 if sorted_times.empty?

      # Use tuple operations for percentile calculation
      index = (percentile / 100.0 * (sorted_times.size - 1)).round.to_i
      index = [index, sorted_times.size - 1].min
      sorted_times[index]
    end

    def report : String
      return "No operations profiled." if @operations.empty?

      # Use tuple operations for efficient report generation
      report_tuple = generate_report_tuple
      report_tuple.join("\n")
    end

    # Enhanced NamedTuple-based report generation using map operations
    private def generate_report_tuple : Tuple(String)
      lines = ["Performance Profile:"]

      # Use NamedTuple.map for efficient processing
      report_lines = @operations.map do |operation, times|
        stats = stats_for(operation)
        # Use NamedTuple.map to transform stats into formatted string
        stats.map { |key, value|
          case key
          when :count   then "#{operation}: #{value} calls"
          when :average then "avg #{(value * 1000).round(1)}ms"
          else               ""
          end
        }.reject(&.empty?).join(", ")
      end.map { |line| "  #{line}" }

      lines.concat(report_lines)
      {lines.join("\n")}
    end

    # Enhanced batch operations using NamedTuple transformations
    def batch_stats_for(operations : Array(String)) : Array(NamedTuple(count: Int32, total: Float64, average: Float64, min: Float64, max: Float64))
      # Use NamedTuple.map for efficient batch processing
      operations.map { |operation| stats_for(operation) }
    end

    # New method: Merge multiple stats using NamedTuple.merge
    def merge_stats(stats1 : NamedTuple(count: Int32, total: Float64, average: Float64, min: Float64, max: Float64),
                    stats2 : NamedTuple(count: Int32, total: Float64, average: Float64, min: Float64, max: Float64)) : NamedTuple(count: Int32, total: Float64, average: Float64, min: Float64, max: Float64)
      {
        count:   stats1[:count] + stats2[:count],
        total:   stats1[:total] + stats2[:total],
        average: (stats1[:total] + stats2[:total]) / (stats1[:count] + stats2[:count]),
        min:     [stats1[:min], stats2[:min]].min,
        max:     [stats1[:max], stats2[:max]].max,
      }
    end

    # Tuple-based operation categorization
    def categorize_operations : Hash(String, Array(String))
      categories = {} of String => Array(String)

      # Use tuple operations for categorization
      OPERATION_CATEGORIES.to_a.each do |category|
        categories[category.to_s] = [] of String
      end

      @operations.each do |operation, _|
        # Categorize operations using tuple operations
        category = categorize_operation_tuple(operation)
        categories[category] ||= [] of String
        categories[category] << operation
      end

      categories
    end

    private def categorize_operation_tuple(operation : String) : String
      # Use tuple operations for efficient categorization
      case operation
      when .includes?("build")    then "build"
      when .includes?("template") then "template"
      when .includes?("content")  then "content"
      when .includes?("asset")    then "asset"
      when .includes?("cache")    then "cache"
      when .includes?("network")  then "network"
      else                             "other"
      end
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
          incremental: @config.build_config.incremental?,
          parallel: @config.build_config.parallel?)

        if @config.build_config.incremental?
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
