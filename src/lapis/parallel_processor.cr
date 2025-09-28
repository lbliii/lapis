require "fiber"
require "channel"
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

  # Parallel processor using Crystal's Fiber system
  class ParallelProcessor
    property config : BuildConfig
    property workers : Array(Fiber)
    property work_channel : Channel(Task)
    property result_channel : Channel(Result)
    property running : Bool = false

    def initialize(@config : BuildConfig)
      # Use bounded channels to prevent memory issues
      @work_channel = Channel(Task).new(@config.max_workers * 2)
      @result_channel = Channel(Result).new(@config.max_workers * 2)
      @workers = [] of Fiber
    end

    def process_parallel(tasks : Array(Task), processor : Proc(Task, Result), timeout : Time::Span? = nil) : Array(Result)
      return [] of Result if tasks.empty?

      Logger.debug("Starting parallel processing",
        tasks: tasks.size.to_s,
        workers: @config.max_workers.to_s,
        timeout: timeout ? "#{timeout.total_seconds}s" : "none")

      start_time = Time.monotonic
      results = [] of Result

      # Create worker fibers
      Logger.debug("Spawning workers")
      spawn_workers(processor)

      # Send tasks to workers
      Logger.debug("Sending tasks to workers")
      tasks.each do |task|
        begin
          @work_channel.send(task)
        rescue Channel::ClosedError
          Logger.error("Work channel closed unexpectedly", task_id: task.id)
          break
        end
      end

      # Collect results with optional timeout
      Logger.debug("Collecting results")
      if timeout
        results = collect_results_with_timeout(tasks.size, timeout)
      else
        results = collect_results(tasks.size)
      end

      Logger.debug("Stopping workers")
      stop_workers

      total_duration = Time.monotonic - start_time
      Logger.info("Parallel processing completed",
        tasks: tasks.size.to_s,
        successful: results.count(&.success).to_s,
        failed: results.count { |r| !r.success }.to_s,
        total_duration: "#{total_duration.total_milliseconds}ms")

      results
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

    private def spawn_workers(processor : Proc(Task, Result))
      worker_count = @config.max_workers

      worker_count.times do |i|
        worker = spawn do
          Logger.debug("Worker #{i} started")

          loop do
            begin
              task = @work_channel.receive
              break if task.id == "STOP"

              begin
                result = processor.call(task)
                @result_channel.send(result)
              rescue ex
                error_result = Result.new(task.id, false, nil, ex.message)
                @result_channel.send(error_result)
              end
            rescue Channel::ClosedError
              Logger.debug("Worker #{i} received channel closed signal")
              break
            end
          end

          Logger.debug("Worker #{i} stopped")
        end

        @workers << worker
      end

      @running = true
      Logger.debug("Spawned #{worker_count} workers")
    end

    private def stop_workers
      return unless @running

      Logger.debug("Sending stop signals to workers")
      # Send stop signals to all workers
      @config.max_workers.times do
        stop_task = Task.new("STOP", "", :stop)
        @work_channel.send(stop_task)
      end

      Logger.debug("Waiting for workers to finish")
      # Wait for workers to finish - fibers automatically finish when their block ends
      @workers.clear
      @running = false

      Logger.debug("All workers stopped")
    end

    private def collect_results(expected_count : Int32) : Array(Result)
      results = [] of Result
      expected_count.times do
        begin
          result = @result_channel.receive
          results << result

          if result.success
            Logger.debug("Task completed",
              task_id: result.task_id,
              duration: "#{result.duration.total_milliseconds}ms")
          else
            Logger.error("Task failed",
              task_id: result.task_id,
              error: result.error)
          end
        rescue Channel::ClosedError
          Logger.error("Result channel closed unexpectedly")
          break
        end
      end
      results
    end

    private def collect_results_with_timeout(expected_count : Int32, timeout : Time::Span) : Array(Result)
      results = [] of Result
      start_time = Time.monotonic

      expected_count.times do
        remaining_time = timeout - (Time.monotonic - start_time)
        break if remaining_time <= Time::Span.new(seconds: 0)

        begin
          result = select
          when r = @result_channel.receive
            r
          when timeout(remaining_time)
            Logger.warn("Parallel processing timeout",
              expected: expected_count.to_s,
              received: results.size.to_s,
              timeout: timeout.total_seconds.to_s)
            break
          end

          results << result

          if result.success
            Logger.debug("Task completed",
              task_id: result.task_id,
              duration: "#{result.duration.total_milliseconds}ms")
          else
            Logger.error("Task failed",
              task_id: result.task_id,
              error: result.error)
          end
        rescue Channel::ClosedError
          Logger.error("Result channel closed unexpectedly")
          break
        end
      end
      results
    end
  end
end
