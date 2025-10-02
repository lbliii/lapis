require "process"
require "log"
require "./logger"
require "./exceptions"

module Lapis
  # Process management for external tools and subprocesses
  class ProcessManager
    property processes : Hash(String, Process) = {} of String => Process
    property process_timeout : Time::Span = 30.seconds
    property max_concurrent_processes : Int32 = 4
    property max_processes_cache : Int32 = 100

    def initialize(@process_timeout : Time::Span = 30.seconds, @max_concurrent_processes : Int32 = 4, setup_termination : Bool = true)
      setup_termination_handler if setup_termination
      # Check initial memory usage
      memory_manager = Lapis.memory_manager
      memory_manager.check_collection_size("processes", @processes.size)
    end

    # Setup graceful termination handler using Process.on_terminate
    private def setup_termination_handler
      # Skip if in test mode or if handler is already set up
      return if ENV.fetch("LAPIS_TEST_MODE", "false") == "true"
      Process.on_terminate do |reason|
        case reason
        when .interrupted?
          Logger.info("Received interrupt signal, cleaning up processes...")
          cleanup
        when .terminal_disconnected?
          Logger.info("Terminal disconnected, cleaning up processes...")
          cleanup
        when .session_ended?
          Logger.info("Session ended, cleaning up processes...")
          cleanup
        end
      end
    end

    # Execute a command and return the result
    def execute(command : String, args : Array(String) = [] of String,
                input : String? = nil, timeout : Time::Span? = nil) : ProcessResult
      Logger.debug("Executing command", command: command, args: args.join(" "))

      timeout = timeout || @process_timeout

      begin
        process = Process.new(command, args,
          input: input ? Process::Redirect::Pipe : Process::Redirect::Close,
          output: Process::Redirect::Pipe,
          error: Process::Redirect::Pipe)

        # Send input if provided
        if input && process.input
          begin
            process.input.try(&.print(input))
          ensure
            process.input.try(&.close)
          end
        end

        # Wait for process completion with timeout
        done_channel = Channel(Process::Status).new
        spawn do
          status = process.wait
          done_channel.send(status)
        end

        status = select
        when result = done_channel.receive
          result
        when timeout(timeout)
          process.terminate
          raise ProcessError.new("Command '#{command}' timed out after #{timeout.total_seconds}s")
        end

        # Read output with memory limits to prevent excessive memory usage
        max_output_size = 1024 * 1024 # 1MB limit
        output = ""
        error_output = ""
        # Read output with size limits
        if process.output
          output = process.output.try(&.gets_to_end) || ""
          if output.size > max_output_size
            Logger.warn("Process output truncated due to size limit",
              size: output.size, limit: max_output_size)
            output = output[0, max_output_size] + "\n... (truncated)"
          end
        end

        # Read error output with size limits
        if process.error
          error_output = process.error.try(&.gets_to_end) || ""
          if error_output.size > max_output_size
            Logger.warn("Process error output truncated due to size limit",
              size: error_output.size, limit: max_output_size)
            error_output = error_output[0, max_output_size] + "\n... (truncated)"
          end
        end

        result = ProcessResult.new(
          command: command,
          args: args,
          status: status,
          output: output,
          error: error_output,
          success: status.success?
        )

        Logger.info("Command executed",
          command: command,
          success: result.success.to_s,
          exit_code: status.exit_code.to_s,
          output_size: output.size.to_s)

        result
      rescue ex
        Logger.error("Unexpected process error", command: command, error: ex.message)
        raise ProcessError.new("Unexpected error executing '#{command}': #{ex.message}")
      end
    end

    # Execute a command asynchronously
    def execute_async(command : String, args : Array(String) = [] of String,
                      input : String? = nil) : String
      process_id = "#{command}_#{Time.utc.to_unix}"

      Logger.debug("Executing command asynchronously",
        command: command,
        process_id: process_id)

      process = Process.new(command, args,
        input: input ? Process::Redirect::Pipe : Process::Redirect::Close,
        output: Process::Redirect::Pipe,
        error: Process::Redirect::Pipe)

      @processes[process_id] = process

      # Check if processes cache is getting too large
      if @processes.size > @max_processes_cache
        Logger.warn("Process cache too large, cleaning up old processes",
          current_size: @processes.size,
          max_size: @max_processes_cache)
        cleanup_old_processes
      end

      # Send input if provided
      if input && process.input
        begin
          process.input.try(&.print(input))
        ensure
          process.input.try(&.close)
        end
      end

      Logger.info("Command started asynchronously",
        command: command,
        process_id: process_id)

      process_id
    end

    # Wait for an async process to complete
    def wait_for_process(process_id : String, timeout : Time::Span? = nil) : ProcessResult?
      process = @processes[process_id]?
      return nil unless process

      Logger.debug("Waiting for process", process_id: process_id)

      timeout = timeout || @process_timeout

      begin
        done_channel = Channel(Process::Status).new
        spawn do
          status = process.wait
          done_channel.send(status)
        end

        status = select
        when result = done_channel.receive
          result
        when timeout(timeout)
          process.terminate
          @processes.delete(process_id)
          raise ProcessError.new("Process '#{process_id}' timed out")
        end

        # Read output
        output = process.output.try(&.gets_to_end) || ""
        error_output = process.error.try(&.gets_to_end) || ""

        result = ProcessResult.new(
          command: process_id.split("_")[0],
          args: [] of String,
          status: status,
          output: output,
          error: error_output,
          success: status.success?
        )

        @processes.delete(process_id)

        Logger.info("Async process completed",
          process_id: process_id,
          success: result.success.to_s,
          exit_code: status.exit_code.to_s)

        result
      rescue ex
        Logger.error("Error waiting for async process", process_id: process_id, error: ex.message)
        @processes.delete(process_id)
        raise ProcessError.new("Error waiting for process '#{process_id}': #{ex.message}")
      end
    end

    # Kill a running process
    def kill_process(process_id : String) : Bool
      process = @processes[process_id]?
      return false unless process

      Logger.warn("Killing process", process_id: process_id)

      begin
        process.terminate
        @processes.delete(process_id)
        Logger.info("Process killed", process_id: process_id)
        true
      rescue ex
        Logger.error("Failed to kill process", process_id: process_id, error: ex.message)
        false
      end
    end

    # Get list of running processes
    def running_processes : Array(String)
      @processes.keys
    end

    # Clean up all processes
    def cleanup
      Logger.info("Cleaning up processes", count: @processes.size.to_s)

      @processes.each do |process_id, process|
        begin
          process.terminate
          Logger.debug("Killed process during cleanup", process_id: process_id)
        rescue ex
          Logger.warn("Failed to kill process during cleanup",
            process_id: process_id,
            error: ex.message)
        end
      end

      @processes.clear
      Logger.info("Process cleanup completed")
      # Force periodic cleanup
      memory_manager = Lapis.memory_manager
      memory_manager.periodic_cleanup
    end

    # Clean up old processes to prevent memory leaks
    private def cleanup_old_processes
      processes_to_remove = [] of String
      @processes.each do |process_id, process|
        if process.terminated?
          processes_to_remove << process_id
        end
      end

      processes_to_remove.each do |process_id|
        @processes.delete(process_id)
        Logger.debug("Removed terminated process", process_id: process_id)
      end

      Logger.info("Cleaned up old processes", removed: processes_to_remove.size)
    end

    # Execute a shell command using Process.run with shell parameter
    def shell_execute(command : String, timeout : Time::Span? = nil) : ProcessResult
      Logger.debug("Executing shell command", command: command)

      begin
        # Use Process.run with shell: true for simpler shell execution
        output = IO::Memory.new
        error = IO::Memory.new
        status = Process.run(command, shell: true, output: output, error: error)

        result = ProcessResult.new(
          command: command,
          args: [] of String,
          status: status,
          output: output.to_s,
          error: error.to_s,
          success: status.success?
        )

        Logger.info("Shell command executed",
          command: command,
          success: result.success.to_s,
          exit_code: status.exit_code.to_s)

        result
      rescue ex
        Logger.error("Unexpected shell command error", command: command, error: ex.message)
        raise ProcessError.new("Unexpected error executing shell command '#{command}': #{ex.message}")
      end
    end

    # Execute a shell command with proper argument quoting using Process.quote
    def safe_shell_execute(command : String, args : Array(String) = [] of String) : ProcessResult
      Logger.debug("Executing safe shell command", command: command, args: args.join(" "))

      begin
        # Use Process.quote to safely escape arguments
        quoted_args = args.map { |arg| Process.quote(arg) }
        full_command = "#{command} #{quoted_args.join(" ")}"
        output = IO::Memory.new
        error = IO::Memory.new
        status = Process.run(full_command, shell: true, output: output, error: error)

        result = ProcessResult.new(
          command: command,
          args: args,
          status: status,
          output: output.to_s,
          error: error.to_s,
          success: status.success?
        )

        Logger.info("Safe shell command executed",
          command: command,
          success: result.success.to_s,
          exit_code: status.exit_code.to_s)

        result
      rescue ex
        Logger.error("Unexpected safe shell command error", command: command, error: ex.message)
        raise ProcessError.new("Unexpected error executing safe shell command '#{command}': #{ex.message}")
      end
    end

    # Check if a command exists using Process.run
    def command_exists?(command : String) : Bool
      Process.run("which", [command], output: Process::Redirect::Close, error: Process::Redirect::Close).success?
    rescue
      false
    end

    # Get command version using Process.run
    def get_command_version(command : String, version_flag : String = "--version") : String?
      begin
        Process.run(command, [version_flag], output: Process::Redirect::Pipe) do |process|
          if process.wait.success?
            process.output.try(&.gets_to_end).try(&.strip)
          else
            nil
          end
        end
      rescue
        nil
      end
    end
  end

  # Result of a process execution
  class ProcessResult
    property command : String
    property args : Array(String)
    property status : Process::Status
    property output : String
    property error : String
    property success : Bool

    def initialize(@command : String, @args : Array(String), @status : Process::Status,
                   @output : String, @error : String, @success : Bool)
    end

    def exit_code : Int32
      @status.exit_code
    end

    def to_s : String
      "ProcessResult(command=#{@command}, success=#{@success}, exit_code=#{exit_code})"
    end
  end

  # Global process manager instance
  @@process_manager : ProcessManager?

  def self.process_manager : ProcessManager
    @@process_manager ||= ProcessManager.new(setup_termination: false)
  end

  def self.process_manager=(manager : ProcessManager)
    @@process_manager = manager
  end
end
