require "math"
require "./function_registry"

module Lapis
  # Mathematical functions leveraging Crystal's Math module
  module MathFunctions
    extend self

    def register_functions
      FunctionRegistry.register_function(:add, 2) do |args|
        a = args[0].to_f?
        b = args[1].to_f?
        raise ArgumentError.new("add arguments must be numeric") if !a || !b
        (a + b).to_s
      end

      FunctionRegistry.register_function(:subtract, 2) do |args|
        a = args[0].to_f?
        b = args[1].to_f?
        raise ArgumentError.new("subtract arguments must be numeric") if !a || !b
        (a - b).to_s
      end

      FunctionRegistry.register_function(:multiply, 2) do |args|
        a = args[0].to_f?
        b = args[1].to_f?
        raise ArgumentError.new("multiply arguments must be numeric") if !a || !b
        (a * b).to_s
      end

      FunctionRegistry.register_function(:divide, 2) do |args|
        a = args[0].to_f?
        b = args[1].to_f?
        raise ArgumentError.new("divide arguments must be numeric") if !a || !b
        raise ArgumentError.new("divide by zero") if b == 0.0
        (a / b).to_s
      end

      FunctionRegistry.register_function(:modulo, 2) do |args|
        a = args[0].to_i?
        b = args[1].to_i?
        raise ArgumentError.new("modulo arguments must be integers") if !a || !b
        raise ArgumentError.new("modulo by zero") if b == 0
        (a % b).to_s
      end

      FunctionRegistry.register_function(:round, 2) do |args|
        value = args[0].to_f?
        raise ArgumentError.new("round first argument must be numeric") unless value
        precision = args[1]?.try(&.to_i?) || 0
        value.round(precision).to_s
      end

      FunctionRegistry.register_function(:ceil, 1) do |args|
        value = args[0].to_f?
        raise ArgumentError.new("ceil argument must be numeric") unless value
        value.ceil.to_s
      end

      FunctionRegistry.register_function(:floor, 1) do |args|
        value = args[0].to_f?
        raise ArgumentError.new("floor argument must be numeric") unless value
        value.floor.to_s
      end

      FunctionRegistry.register_function(:abs, 1) do |args|
        value = args[0].to_f?
        raise ArgumentError.new("abs argument must be numeric") unless value
        value.abs.to_s
      end

      FunctionRegistry.register_function(:sqrt, 1) do |args|
        value = args[0].to_f?
        raise ArgumentError.new("sqrt argument must be numeric") unless value
        raise ArgumentError.new("sqrt of negative number") if value < 0.0
        Math.sqrt(value).to_s
      end

      FunctionRegistry.register_function(:pow, 2) do |args|
        base = args[0].to_f?
        exponent = args[1].to_f?
        raise ArgumentError.new("pow arguments must be numeric") if !base || !exponent
        (base ** exponent).to_s
      end

      FunctionRegistry.register_function(:min, 0) do |args|
        values = args.compact_map(&.to_f?)
        raise ArgumentError.new("min arguments must be numeric") if values.size != args.size
        values.min.to_s
      end

      FunctionRegistry.register_function(:max, 0) do |args|
        values = args.compact_map(&.to_f?)
        raise ArgumentError.new("max arguments must be numeric") if values.size != args.size
        values.max.to_s
      end

      FunctionRegistry.register_function(:sum, 0) do |args|
        values = args.compact_map(&.to_f?)
        raise ArgumentError.new("sum arguments must be numeric") if values.size != args.size
        values.sum.to_s
      end
    end
  end
end
