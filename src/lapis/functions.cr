require "./function_registry"

module Lapis
  # Main Functions class - now delegates to FunctionRegistry for modular organization
  class Functions
    # Initialize the function system
    def self.setup
      FunctionRegistry.setup
    end

    # Call a function by name with arguments
    def self.call(name : String, args : Array(String)) : String
      FunctionRegistry.call(name, args)
    end

    # Get list of available functions
    def self.function_list : Array(String)
      FunctionRegistry.function_list
    end

    # Check if a function exists
    def self.has_function?(name : String) : Bool
      FunctionRegistry.has_function?(name)
    end

    # Clear the function cache
    def self.clear_cache
      FunctionRegistry.clear_cache
    end

    # Get cache statistics
    def self.cache_stats : Hash(String, Int32)
      FunctionRegistry.cache_stats
    end
  end
end
