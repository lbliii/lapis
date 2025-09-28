require "file_utils"
require "yaml"
require "log"
require "./logger"
require "./exceptions"

module Lapis
  # Incremental build system with file change tracking
  class IncrementalBuilder
    property cache_dir : String
    property file_timestamps : Hash(String, Time) = {} of String => Time
    property dependencies : Hash(String, Array(String)) = {} of String => Array(String)
    property build_cache : Hash(String, String) = {} of String => String

    def initialize(@cache_dir : String)
      Logger.debug("Initializing incremental builder", cache_dir: @cache_dir)
      Dir.mkdir_p(@cache_dir)
      initialize_cache_files
      load_cache
      Logger.debug("Incremental builder initialized",
        cache_dir: @cache_dir,
        cached_files: @file_timestamps.size,
        dependencies: @dependencies.size,
        build_cache_entries: @build_cache.size)
    end

    def needs_rebuild?(file_path : String) : Bool
      return true unless File.exists?(file_path)

      current_time = File.info(file_path).modification_time
      cached_time = @file_timestamps[file_path]?

      if cached_time.nil?
        Logger.debug("File needs rebuild (no cache)", file: file_path)
        return true
      end

      # Check if file itself changed
      if current_time > cached_time
        Logger.debug("File needs rebuild (modified)",
          file: file_path,
          cached_time: cached_time.to_s,
          current_time: current_time.to_s)
        return true
      end

      # Check if any dependencies changed
      if deps = @dependencies[file_path]?
        deps.each do |dep|
          if needs_rebuild?(dep)
            Logger.debug("File needs rebuild (dependency changed)",
              file: file_path,
              dependency: dep)
            return true
          end
        end
      end

      Logger.debug("File unchanged", file: file_path)
      false
    end

    def add_dependency(file_path : String, dependency : String)
      @dependencies[file_path] ||= [] of String
      @dependencies[file_path] << dependency unless @dependencies[file_path].includes?(dependency)
    end

    def update_timestamp(file_path : String)
      return unless File.exists?(file_path)
      @file_timestamps[file_path] = File.info(file_path).modification_time
    end

    def cache_build_result(file_path : String, result : String)
      @build_cache[file_path] = result
    end

    def get_cached_result(file_path : String) : String?
      @build_cache[file_path]?
    end

    def invalidate_cache(file_path : String)
      @file_timestamps.delete(file_path)
      @build_cache.delete(file_path)
      @dependencies.delete(file_path)
    end

    def invalidate_dependent_files(file_path : String)
      @dependencies.each do |dependent, deps|
        if deps.includes?(file_path)
          invalidate_cache(dependent)
          invalidate_dependent_files(dependent) # Recursive invalidation
        end
      end
    end

    def save_cache
      Logger.debug("Saving cache",
        cache_dir: @cache_dir,
        timestamps: @file_timestamps.size,
        dependencies: @dependencies.size,
        build_cache: @build_cache.size)
      save_timestamps
      save_dependencies
      save_build_cache
      Logger.debug("Cache saved successfully")
    end

    def clear_cache
      @file_timestamps.clear
      @dependencies.clear
      @build_cache.clear

      if Dir.exists?(@cache_dir)
        FileUtils.rm_rf(@cache_dir)
        Dir.mkdir_p(@cache_dir)
      end
    end

    def cache_stats : Hash(String, Int32)
      {
        "cached_files"        => @file_timestamps.size,
        "dependencies"        => @dependencies.size,
        "build_cache_entries" => @build_cache.size,
      }
    end

    private def initialize_cache_files
      # Create empty cache files if they don't exist
      cache_files = {
        File.join(@cache_dir, "timestamps.yml")    => ({} of String => String).to_yaml,
        File.join(@cache_dir, "dependencies.yml")  => ({} of String => Array(String)).to_yaml,
        File.join(@cache_dir, "build_cache.yml")   => ({} of String => String).to_yaml
      }

      cache_files.each do |file, initial_content|
        File.write(file, initial_content) unless File.exists?(file)
      end
    end

    private def load_cache
      load_timestamps
      load_dependencies
      load_build_cache
    end

    private def load_timestamps
      timestamps_file = File.join(@cache_dir, "timestamps.yml")
      return unless File.exists?(timestamps_file)

      begin
        timestamps_data = YAML.parse(File.read(timestamps_file))
        timestamps_data.as_h.each do |path, time_str|
          @file_timestamps[path.to_s] = Time.parse(time_str.to_s, "%Y-%m-%d %H:%M:%S", Time::Location::UTC)
        end
        Logger.debug("Loaded #{@file_timestamps.size} file timestamps")
      rescue ex
        Logger.warn("Failed to load timestamps cache", error: ex.message)
      end
    end

    private def load_dependencies
      dependencies_file = File.join(@cache_dir, "dependencies.yml")
      return unless File.exists?(dependencies_file)

      begin
        deps_data = YAML.parse(File.read(dependencies_file))
        deps_data.as_h.each do |file, deps_array|
          deps = deps_array.as_a.map(&.to_s)
          @dependencies[file.to_s] = deps
        end
        Logger.debug("Loaded #{@dependencies.size} dependency entries")
      rescue ex
        Logger.warn("Failed to load dependencies cache", error: ex.message)
      end
    end

    private def load_build_cache
      cache_file = File.join(@cache_dir, "build_cache.yml")
      return unless File.exists?(cache_file)

      begin
        cache_data = YAML.parse(File.read(cache_file))
        cache_data.as_h.each do |file, content|
          @build_cache[file.to_s] = content.to_s
        end
        Logger.debug("Loaded #{@build_cache.size} build cache entries")
      rescue ex
        Logger.warn("Failed to load build cache", error: ex.message)
      end
    end

    private def save_timestamps
      timestamps_file = File.join(@cache_dir, "timestamps.yml")
      timestamps_data = @file_timestamps.transform_values(&.to_s("%Y-%m-%d %H:%M:%S"))

      File.write(timestamps_file, timestamps_data.to_yaml)
      Logger.debug("Saved #{@file_timestamps.size} file timestamps")
    end

    private def save_dependencies
      dependencies_file = File.join(@cache_dir, "dependencies.yml")
      File.write(dependencies_file, @dependencies.to_yaml)
      Logger.debug("Saved #{@dependencies.size} dependency entries")
    end

    private def save_build_cache
      cache_file = File.join(@cache_dir, "build_cache.yml")
      File.write(cache_file, @build_cache.to_yaml)
      Logger.debug("Saved #{@build_cache.size} build cache entries")
    end
  end
end
