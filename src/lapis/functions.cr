module Lapis
  class Functions
    # Function registry - simplified for now
    FUNCTIONS = {} of String => Proc(Array(String), String)

    # Register all function categories
    def self.setup
      register_string_functions
      register_array_functions
      register_math_functions
      register_time_functions
      register_hash_functions
      register_url_functions
      register_logic_functions
      register_type_functions
    end

    def self.call(name : String, args : Array(String)) : String
      if func = FUNCTIONS[name]?
        func.call(args)
      else
        ""
      end
    end

    def self.function_list : Array(String)
      FUNCTIONS.keys
    end

    def self.has_function?(name : String) : Bool
      FUNCTIONS.has_key?(name)
    end

    # STRING FUNCTIONS
    private def self.register_string_functions
      # Basic string manipulation
      FUNCTIONS["upper"] = ->(args : Array(String)) : String {
        args[0] ? args[0].upcase : ""
      }

      FUNCTIONS["lower"] = ->(args : Array(String)) : String {
        args[0] ? args[0].downcase : ""
      }

      FUNCTIONS["title"] = ->(args : Array(String)) : String {
        args[0] ? args[0].split.map(&.capitalize).join(" ") : ""
      }

      FUNCTIONS["trim"] = ->(args : Array(String)) : String {
        args[0] ? args[0].strip : ""
      }

      FUNCTIONS["slugify"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
      }
    end

    # ARRAY FUNCTIONS
    private def self.register_array_functions
      FUNCTIONS["len"] = ->(args : Array(String)) : String {
        args[0] ? args[0].size.to_s : "0"
      }
    end

    # MATH FUNCTIONS
    private def self.register_math_functions
      FUNCTIONS["add"] = ->(args : Array(String)) : String {
        a = args[0] ? args[0].to_i? || 0 : 0
        b = args[1] ? args[1].to_i? || 0 : 0
        (a + b).to_s
      }
    end

    # TIME FUNCTIONS
    private def self.register_time_functions
      FUNCTIONS["now"] = ->(args : Array(String)) : String {
        Time.utc.to_s("%Y-%m-%d %H:%M:%S")
      }
    end

    # HASH FUNCTIONS
    private def self.register_hash_functions
      # Placeholder for hash functions
    end

    # URL FUNCTIONS
    private def self.register_url_functions
      FUNCTIONS["urlize"] = ->(args : Array(String)) : String {
        str = args[0] || ""
        str.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
      }
    end

    # LOGIC FUNCTIONS
    private def self.register_logic_functions
      FUNCTIONS["eq"] = ->(args : Array(String)) : String {
        args[0] == args[1] ? "true" : "false"
      }
    end

    # TYPE FUNCTIONS
    private def self.register_type_functions
      FUNCTIONS["string"] = ->(args : Array(String)) : String {
        args[0] || ""
      }
    end
  end
end