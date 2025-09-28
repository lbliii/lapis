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

    def initialize(@memory_threshold : Int64 = 100_i64 * 1024 * 1024)
      @stats = nil
      @gc_enabled = true
    end

    # Enable or disable GC for performance-critical operations
    def with_gc_disabled(&block)
      old_gc_enabled = @gc_enabled
      @gc_enabled = false
      GC.disable
      
      begin
        yield
      ensure
        @gc_enabled = old_gc_enabled
        GC.enable if @gc_enabled
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
      
      current_memory = @stats.not_nil!.heap_size
      pressure = current_memory > @memory_threshold
      
      if pressure
        Logger.warn("Memory pressure detected", 
          current: format_bytes(current_memory),
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
      
      stats = @stats.not_nil!
      heap_size = stats.heap_size.to_i64
      free_bytes = stats.free_bytes.to_i64
      {
        "heap_size" => format_bytes(heap_size),
        "heap_size_bytes" => heap_size.to_s,
        "heap_used" => format_bytes(heap_size - free_bytes),
        "heap_used_bytes" => (heap_size - free_bytes).to_s,
        "free_bytes" => format_bytes(free_bytes),
        "free_bytes_raw" => free_bytes.to_s
      }
    end

    # Monitor memory usage during an operation
    def monitor_operation(operation_name : String, &block)
      Logger.debug("Starting memory monitoring", operation: operation_name)
      
      start_memory = current_memory_usage
      start_time = Time.monotonic
      
      result = yield
      
      end_memory = current_memory_usage
      end_time = Time.monotonic
      
      memory_delta = end_memory - start_memory
      duration = end_time - start_time
      
      Logger.info("Operation completed", 
        operation: operation_name,
        duration: format_duration(duration),
        memory_start: format_bytes(start_memory),
        memory_end: format_bytes(end_memory),
        memory_delta: format_bytes(memory_delta))
      
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
    def optimize_for_large_operation(&block)
      Logger.debug("Optimizing memory for large operation")
      
      # Force GC before starting
      force_gc
      
      # Disable GC during operation for performance
      with_gc_disabled do
        yield
      end
      
      # Force GC after completion
      force_gc
    end

    # Memory profiling for build operations
    def profile_build_operation(operation_name : String, &block)
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
    end

    private def update_stats
      @stats = GC.stats
    end

    # Format bytes for display
    def format_bytes(bytes : Int64) : String
      if bytes < 1024
        "#{bytes} B"
      elsif bytes < 1024 * 1024
        "#{bytes / 1024} KB"
      elsif bytes < 1024 * 1024 * 1024
        "#{bytes / (1024 * 1024)} MB"
      else
        "#{bytes / (1024 * 1024 * 1024)} GB"
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
