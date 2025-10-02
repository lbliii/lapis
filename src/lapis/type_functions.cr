require "./function_registry"

module Lapis
  # Type conversion and validation functions
  module TypeFunctions
    extend self

    def register_functions
      FunctionRegistry.register_function(:string, 1) do |args|
        args[0] || ""
      end

      FunctionRegistry.register_function(:int, 1) do |args|
        raise ArgumentError.new("int requires exactly 1 argument") if args.size != 1
        value = args[0].to_i?
        raise ArgumentError.new("int argument must be numeric") unless value
        value.to_s
      end

      FunctionRegistry.register_function(:float, 1) do |args|
        raise ArgumentError.new("float requires exactly 1 argument") if args.size != 1
        value = args[0].to_f?
        raise ArgumentError.new("float argument must be numeric") unless value
        value.to_s
      end

      FunctionRegistry.register_function(:bool, 1) do |args|
        raise ArgumentError.new("bool requires exactly 1 argument") if args.size != 1
        arg = args[0]
        (arg == "true" || arg == "1" || arg != "") ? "true" : "false"
      end

      FunctionRegistry.register_function(:array, 0) do |args|
        args.join(",")
      end

      FunctionRegistry.register_function(:size, 1) do |args|
        raise ArgumentError.new("size requires exactly 1 argument") if args.size != 1
        args[0].size.to_s
      end

      FunctionRegistry.register_function(:empty, 1) do |args|
        raise ArgumentError.new("empty requires exactly 1 argument") if args.size != 1
        arg = args[0]
        arg.empty? ? "true" : "false"
      end

      FunctionRegistry.register_function(:blank, 1) do |args|
        raise ArgumentError.new("blank requires exactly 1 argument") if args.size != 1
        arg = args[0]
        arg.strip.empty? ? "true" : "false"
      end
    end
  end
end
