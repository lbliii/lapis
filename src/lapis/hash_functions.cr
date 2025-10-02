require "./function_registry"

module Lapis
  # Hash manipulation functions leveraging Crystal's Hash methods
  module HashFunctions
    extend self

    def register_functions
      FunctionRegistry.register_function(:"has_key", 2) do |args|
        # This would need context from the template processor
        "false" # Placeholder
      end

      FunctionRegistry.register_function(:keys, 1) do |args|
        # This would need context from the template processor
        "" # Placeholder
      end

      FunctionRegistry.register_function(:values, 1) do |args|
        # This would need context from the template processor
        "" # Placeholder
      end
    end
  end
end
