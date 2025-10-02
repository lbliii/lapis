require "./function_registry"

module Lapis
  # File system operations functions
  module FileFunctions
    extend self

    def register_functions
      FunctionRegistry.register_function(:"file_exists", 1) do |args|
        file_path = args[0]? || ""
        File.exists?(file_path) ? "true" : "false"
      end

      FunctionRegistry.register_function(:"file_size", 1) do |args|
        file_path = args[0]? || ""
        begin
          File.size(file_path).to_s
        rescue
          "0"
        end
      end

      FunctionRegistry.register_function(:"file_extension", 1) do |args|
        file_path = args[0]? || ""
        File.extname(file_path)
      end

      FunctionRegistry.register_function(:"file_extname", 1) do |args|
        file_path = args[0]? || ""
        Path[file_path].extension
      end

      FunctionRegistry.register_function(:"file_basename", 1) do |args|
        file_path = args[0]? || ""
        Path[file_path].basename
      end

      FunctionRegistry.register_function(:"file_dirname", 1) do |args|
        file_path = args[0]? || ""
        Path[file_path].parent.to_s
      end
    end
  end
end
