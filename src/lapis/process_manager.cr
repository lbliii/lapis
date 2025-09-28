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

    def initialize(@process_timeout : Time::Span = 30.seconds, @max_concurrent_processes : Int32 = 4)
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
          process.input.not_nil!.print(input)
          process.input.not_nil!.close
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

        # Read output
        output = process.output.try(&.gets_to_end) || ""
        error_output = process.error.try(&.gets_to_end) || ""

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

      # Send input if provided
      if input && process.input
        process.input.not_nil!.print(input)
        process.input.not_nil!.close
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
    end

    # Execute a shell command
    def shell_execute(command : String, timeout : Time::Span? = nil) : ProcessResult
      Logger.debug("Executing shell command", command: command)

      execute("sh", ["-c", command], timeout: timeout)
    end

    # Check if a command exists
    def command_exists?(command : String) : Bool
      result = execute("which", [command])
      result.success
    rescue
      false
    end

    # Get command version
    def get_command_version(command : String, version_flag : String = "--version") : String?
      result = execute(command, [version_flag])
      result.success ? result.output.strip : nil
    rescue
      nil
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
    @@process_manager ||= ProcessManager.new
  end

  def self.process_manager=(manager : ProcessManager)
    @@process_manager = manager
  end
end
