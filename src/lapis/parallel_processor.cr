require "fiber"
require "channel"
require "wait_group"
require "log"
require "./logger"
require "./exceptions"
require "./config"

module Lapis
  # Task for parallel processing
  struct Task
    property id : String
    property file_path : String
    property task_type : Symbol
    property data : Hash(String, String)

    def initialize(@id : String, @file_path : String, @task_type : Symbol, @data : Hash(String, String) = {} of String => String)
    end
  end

  # Result from parallel processing
  struct Result
    property task_id : String
    property success : Bool
    property output : String?
    property error : String?
    property duration : Time::Span

    def initialize(@task_id : String, @success : Bool, @output : String? = nil, @error : String? = nil, @duration : Time::Span = Time::Span.new(seconds: 0))
    end
  end

  # Parallel processor using Crystal's WaitGroup for synchronization
  class ParallelProcessor
    property config : BuildConfig
    property results : Array(Result) = [] of Result
    property results_mutex : Mutex = Mutex.new

    def initialize(@config : BuildConfig)
    end

    def process_parallel(tasks : Array(Task), processor : Proc(Task, Result), timeout : Time::Span? = nil) : Array(Result)
      return [] of Result if tasks.empty?

      Logger.debug("Starting parallel processing",
        tasks: tasks.size.to_s,
        workers: @config.max_workers.to_s,
        timeout: timeout ? "#{timeout.total_seconds}s" : "none")

      start_time = Time.monotonic
      @results.clear

      # Use WaitGroup to coordinate task execution
      WaitGroup.wait do |wg|
        tasks.each do |task|
          wg.spawn do
            start_time = Time.monotonic
            Logger.debug("Processing task", task_id: task.id, file: task.file_path)

            begin
              result = processor.call(task)
              duration = Time.monotonic - start_time

              if result.success
                Logger.debug("Task completed successfully",
                  task_id: result.task_id,
                  duration_ms: duration.total_milliseconds.to_i.to_s)
              else
                Logger.error("Task failed",
                  task_id: result.task_id,
                  error: result.error,
                  duration_ms: duration.total_milliseconds.to_i.to_s)
              end

              # Thread-safe result collection
              @results_mutex.synchronize do
                @results << result
              end
            rescue ex
              duration = Time.monotonic - start_time
              Logger.error("Task failed with exception",
                task_id: task.id,
                error: ex.message,
                duration_ms: duration.total_milliseconds.to_i.to_s)

              error_result = Result.new(task.id, false, nil, ex.message, duration)
              @results_mutex.synchronize do
                @results << error_result
              end
            end
          end
        end
      end

      total_duration = Time.monotonic - start_time
      Logger.info("Parallel processing completed",
        tasks: tasks.size.to_s,
        successful: @results.count(&.success).to_s,
        failed: @results.count { |r| !r.success }.to_s,
        total_duration: "#{total_duration.total_milliseconds}ms")

      @results.dup
    end

    def process_content_parallel(content_files : Array(String), processor : Proc(String, String)) : Array(Result)
      Logger.debug("Starting content parallel processing",
        files: content_files.size.to_s,
        worker_count: @config.max_workers.to_s)

      tasks = content_files.map_with_index do |file_path, index|
        Task.new("content_#{index}", file_path, :content_process)
      end

      content_processor = ->(task : Task) do
        start_time = Time.monotonic
        Logger.debug("Processing task", task_id: task.id, file: task.file_path)

        begin
          output = processor.call(task.file_path)
          duration = Time.monotonic - start_time
          Logger.debug("Task completed successfully",
            task_id: task.id,
            duration_ms: duration.total_milliseconds.to_i.to_s)
          Result.new(task.id, true, output, nil, duration)
        rescue ex
          duration = Time.monotonic - start_time
          Logger.error("Task failed",
            task_id: task.id,
            error: ex.message,
            duration_ms: duration.total_milliseconds.to_i.to_s)
          Result.new(task.id, false, nil, ex.message, duration)
        end
      end

      process_parallel(tasks, content_processor)
    end

    def process_assets_parallel(asset_files : Array(String), processor : Proc(String, String)) : Array(Result)
      tasks = asset_files.map_with_index do |file_path, index|
        Task.new("asset_#{index}", file_path, :asset_process)
      end

      asset_processor = ->(task : Task) do
        start_time = Time.monotonic

        begin
          output = processor.call(task.file_path)
          duration = Time.monotonic - start_time
          Result.new(task.id, true, output, nil, duration)
        rescue ex
          duration = Time.monotonic - start_time
          Result.new(task.id, false, nil, ex.message, duration)
        end
      end

      process_parallel(tasks, asset_processor)
    end
  end
end
