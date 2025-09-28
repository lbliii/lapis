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

    def initialize(@task_id : String, @success : Bool, @output : String? = nil, @error : String? = nil, @duration : Time::Span = Time::Span.new(0))
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
      @work_channel = Channel(Task).new
      @result_channel = Channel(Result).new
      @workers = [] of Fiber
    end

    def process_parallel(tasks : Array(Task), processor : Proc(Task, Result)) : Array(Result)
      return [] of Result if tasks.empty?

      start_time = Time.monotonic
      results = [] of Result
      
      # Create worker fibers
      spawn_workers(processor)
      
      # Send tasks to workers
      tasks.each { |task| @work_channel.send(task) }
      
      # Collect results
      tasks.size.times do
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
      end
      
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
      tasks = content_files.map_with_index do |file_path, index|
        Task.new("content_#{index}", file_path, :content_process)
      end
      
      content_processor = ->(task : Task) do
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
            task = @work_channel.receive
            break if task.id == "STOP"
            
            begin
              result = processor.call(task)
              @result_channel.send(result)
            rescue ex
              error_result = Result.new(task.id, false, nil, ex.message)
              @result_channel.send(error_result)
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
      
      # Send stop signals to all workers
      @config.max_workers.times do
        stop_task = Task.new("STOP", "", :stop)
        @work_channel.send(stop_task)
      end
      
      # Wait for workers to finish
      @workers.each(&.join)
      @workers.clear
      @running = false
      
      Logger.debug("All workers stopped")
    end
  end
end
