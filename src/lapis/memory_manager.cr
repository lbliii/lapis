require "gc"
require "log"
require "./logger"
require "./exceptions"

module Lapis
  # Memory management and GC control for Lapis
  class MemoryManager
    property stats : GC::Stats?
    property memory_threshold : Int64 = 100_i64 * 1024 * 1024 # 100MB
    property gc_enabled : Bool = true
    property max_cache_size : Int32 = 1000
    property collection_size_warning_threshold : Int32 = 10000
    property last_cleanup_time : Time = Time.utc

    def initialize(@memory_threshold : Int64 = 100_i64 * 1024 * 1024)
      @stats = nil
      @gc_enabled = true
      @last_cleanup_time = Time.utc
    end

    # Monitor memory during performance-critical operations
    def with_memory_monitoring(operation_name : String, &)
      Logger.debug("Starting memory monitoring", operation: operation_name)
      start_memory = current_memory_usage

      begin
        result = yield
        end_memory = current_memory_usage
        memory_delta = end_memory - start_memory

        Logger.debug("Memory monitoring completed",
          operation: operation_name,
          memory_delta: format_bytes(memory_delta))

        result
      rescue ex
        Logger.error("Memory monitoring failed",
          operation: operation_name,
          error: ex.message)
        raise ex
      end
    end

    # Execute block with GC disabled
    def with_gc_disabled(&)
      previous_state = @gc_enabled
      @gc_enabled = false
      GC.disable if previous_state
      
      begin
        yield
      ensure
        @gc_enabled = previous_state
        GC.enable if previous_state
      end
    end

    # Force garbage collection
    def force_gc
      Logger.debug("Forcing garbage collection")
      GC.collect
      update_stats
    end

    # Check if memory usage is above threshold
    def memory_pressure? : Bool
      update_stats
      return false unless @stats

      current_memory = @stats.try(&.heap_size) || 0
      pressure = current_memory > @memory_threshold

      if pressure
        Logger.warn("Memory pressure detected",
          current: format_bytes(current_memory.to_i64),
          threshold: format_bytes(@memory_threshold))
      end

      pressure
    end

    # Get current memory usage
    def current_memory_usage : Int64
      update_stats
      @stats.try(&.heap_size).try(&.to_i64) || 0_i64
    end

    # Get memory usage statistics
    def memory_stats : Hash(String, String)
      update_stats
      return {} of String => String unless @stats

      stats = @stats.try { |s| s } || GC.stats
      heap_size = stats.heap_size.to_i64
      free_bytes = stats.free_bytes.to_i64
      {
        "heap_size"       => format_bytes(heap_size),
        "heap_size_bytes" => heap_size.to_s,
        "heap_used"       => format_bytes(heap_size - free_bytes),
        "heap_used_bytes" => (heap_size - free_bytes).to_s,
        "free_bytes"      => format_bytes(free_bytes),
        "free_bytes_raw"  => free_bytes.to_s,
      }
    end

    # Monitor memory usage during an operation with detailed profiling
    def monitor_operation(operation_name : String, &)
      Logger.debug("Starting memory monitoring", operation: operation_name)

      start_memory = current_memory_usage
      start_time = Time.monotonic
      start_stats = GC.stats

      result = yield

      end_memory = current_memory_usage
      end_time = Time.monotonic
      end_stats = GC.stats

      memory_delta = end_memory - start_memory
      duration = end_time - start_time

      # Calculate GC statistics (simplified)
      gc_collections = 0
      gc_time = Time::Span.zero

      Logger.info("Operation completed",
        operation: operation_name,
        duration: format_duration(duration),
        memory_start: format_bytes(start_memory),
        memory_end: format_bytes(end_memory),
        memory_delta: format_bytes(memory_delta),
        gc_collections: gc_collections.to_s,
        gc_time: "#{gc_time.total_milliseconds}ms")

      # Force GC if memory usage increased significantly
      if memory_delta > @memory_threshold / 4
        Logger.warn("High memory usage detected, forcing GC",
          operation: operation_name,
          memory_delta: format_bytes(memory_delta))
        force_gc
      end

      result
    end

    # Optimize memory for large operations
    def optimize_for_large_operation(operation_name : String, &)
      Logger.debug("Optimizing memory for large operation", operation: operation_name)

      # Monitor memory during operation
      with_memory_monitoring(operation_name) do
        yield
      end
    end

    # Memory profiling for build operations
    def profile_build_operation(operation_name : String, &)
      Logger.info("Starting memory profiling", operation: operation_name)

      initial_stats = memory_stats
      start_time = Time.monotonic

      result = monitor_operation(operation_name) do
        yield
      end

      final_stats = memory_stats
      total_time = Time.monotonic - start_time

      Logger.info("Memory profiling completed",
        operation: operation_name,
        total_duration: format_duration(total_time),
        initial_heap: initial_stats["heap_size"],
        final_heap: final_stats["heap_size"],
        peak_memory: format_bytes(current_memory_usage))

      result
    end

    # Clean up resources and force GC
    def cleanup
      Logger.debug("Performing memory cleanup")
      force_gc

      # Log final memory stats
      stats = memory_stats
      Logger.info("Memory cleanup completed",
        heap_size: stats["heap_size"],
        free_bytes: stats["free_bytes"])

      @last_cleanup_time = Time.utc
    end

    # Periodic cleanup for memory management
    def periodic_cleanup
      return unless should_perform_cleanup?

      Logger.debug("Performing periodic memory cleanup")

      # Force GC if memory pressure detected
      if memory_pressure?
        force_gc
      end

      # Log memory stats
      stats = memory_stats
      Logger.info("Periodic cleanup completed",
        heap_size: stats["heap_size"],
        free_bytes: stats["free_bytes"])

      @last_cleanup_time = Time.utc
    end

    # Check if cleanup should be performed (every 5 minutes)
    private def should_perform_cleanup? : Bool
      Time.utc - @last_cleanup_time > 5.minutes
    end

    # Monitor collection sizes and warn if they grow too large
    def check_collection_size(collection_name : String, size : Int32)
      if size > @collection_size_warning_threshold
        Logger.warn("Large collection detected",
          collection: collection_name,
          size: size,
          threshold: @collection_size_warning_threshold)

        # Force cleanup if collection is extremely large
        if size > @collection_size_warning_threshold * 2
          Logger.warn("Extremely large collection, forcing cleanup",
            collection: collection_name,
            size: size)
          force_gc
        end
      end
    end

    # Safe cache addition with size limits
    def add_to_cache_safely(cache : Hash(K, V), key : K, value : V, max_size : Int32? = nil) forall K, V
      max_size ||= @max_cache_size

      if cache.size >= max_size
        # Simple eviction: remove oldest entry
        oldest_key = cache.keys.first
        cache.delete(oldest_key)
        Logger.debug("Cache eviction",
          cache_type: cache.class.name,
          evicted_key: oldest_key.to_s,
          new_size: cache.size)
      end

      cache[key] = value
    end

    private def update_stats
      @stats = GC.stats
    end

    # Format bytes for display
    KB = 1024_i64
    MB = KB * 1024
    GB = MB * 1024

    def format_bytes(bytes : Int64) : String
      if bytes < KB
        "#{bytes} B"
      elsif bytes < MB
        "#{(bytes.to_f / KB).round(2)} KB"
      elsif bytes < GB
        "#{(bytes.to_f / MB).round(2)} MB"
      else
        "#{(bytes.to_f / GB).round(2)} GB"
      end
    end

    # Format duration for logging
    def format_duration(duration : Time::Span) : String
      if duration.total_milliseconds < 1000
        "#{duration.total_milliseconds.round(2)}ms"
      elsif duration.total_seconds < 60
        "#{duration.total_seconds.round(2)}s"
      else
        minutes = (duration.total_seconds / 60).floor
        seconds = duration.total_seconds % 60
        "#{minutes}m #{seconds.round(1)}s"
      end
    end
  end

  # Global memory manager instance
  @@memory_manager : MemoryManager?

  def self.memory_manager : MemoryManager
    @@memory_manager ||= MemoryManager.new
  end

  def self.memory_manager=(manager : MemoryManager)
    @@memory_manager = manager
  end
end
