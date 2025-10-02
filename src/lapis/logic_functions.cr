require "./function_registry"

module Lapis
  # Logic and comparison functions for boolean operations
  module LogicFunctions
    extend self

    def register_functions
      FunctionRegistry.register_function(:eq, 2) do |args|
        args[0] == args[1] ? "true" : "false"
      end

      FunctionRegistry.register_function(:ne, 2) do |args|
        args[0] != args[1] ? "true" : "false"
      end

      FunctionRegistry.register_function(:gt, 2) do |args|
        a = args[0]?.try(&.to_f?) || 0.0
        b = args[1]?.try(&.to_f?) || 0.0
        a > b ? "true" : "false"
      end

      FunctionRegistry.register_function(:lt, 2) do |args|
        a = args[0]?.try(&.to_f?) || 0.0
        b = args[1]?.try(&.to_f?) || 0.0
        a < b ? "true" : "false"
      end

      FunctionRegistry.register_function(:gte, 2) do |args|
        a = args[0]?.try(&.to_f?) || 0.0
        b = args[1]?.try(&.to_f?) || 0.0
        a >= b ? "true" : "false"
      end

      FunctionRegistry.register_function(:lte, 2) do |args|
        a = args[0]?.try(&.to_f?) || 0.0
        b = args[1]?.try(&.to_f?) || 0.0
        a <= b ? "true" : "false"
      end

      FunctionRegistry.register_function(:and, 2) do |args|
        args.all? { |arg| arg == "true" || arg == "1" || arg != "" } ? "true" : "false"
      end

      FunctionRegistry.register_function(:or, 2) do |args|
        args.any? { |arg| arg == "true" || arg == "1" || arg != "" } ? "true" : "false"
      end

      FunctionRegistry.register_function(:not, 1) do |args|
        arg = args[0]? || ""
        (arg == "true" || arg == "1" || arg != "") ? "false" : "true"
      end

      FunctionRegistry.register_function(:contains, 2) do |args|
        haystack = args[0]? || ""
        needle = args[1]? || ""
        haystack.includes?(needle) ? "true" : "false"
      end

      FunctionRegistry.register_function(:"starts_with", 2) do |args|
        str = args[0]? || ""
        prefix = args[1]? || ""
        str.starts_with?(prefix) ? "true" : "false"
      end

      FunctionRegistry.register_function(:"ends_with", 2) do |args|
        str = args[0]? || ""
        suffix = args[1]? || ""
        str.ends_with?(suffix) ? "true" : "false"
      end

      # Range-based functions
      FunctionRegistry.register_function(:"in_range", 3) do |args|
        value = args[0]?.try(&.to_i?) || 0
        min_val = args[1]?.try(&.to_i?) || 0
        max_val = args[2]?.try(&.to_i?) || 0
        range = min_val..max_val
        range.includes?(value) ? "true" : "false"
      end

      FunctionRegistry.register_function(:"range_size", 2) do |args|
        min_val = args[0]?.try(&.to_i?) || 0
        max_val = args[1]?.try(&.to_i?) || 0
        range = min_val..max_val
        range.size.to_s
      end
    end
  end
end
