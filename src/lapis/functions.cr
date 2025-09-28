module Lapis
  class Functions
    # Function registry - simplified for now
    FUNCTIONS = {} of String => Proc(Array(String | Int32 | Bool | Array(String) | Time | Nil), String | Int32 | Bool | Array(String) | Time | Nil)

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

    def self.call(name : String, args : Array(String | Int32 | Bool | Array(String) | Time | Nil)) : (String | Int32 | Bool | Array(String) | Time | Nil)
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

    # Helper method to cast return values to union type
    private def self.cast_result(value) : (String | Int32 | Bool | Array(String) | Time | Nil)
      value.as(String | Int32 | Bool | Array(String) | Time | Nil)
    end

    # STRING FUNCTIONS (Hugo-compatible)
    private def self.register_string_functions
      # Basic string manipulation
      FUNCTIONS["upper"] = ->(args : Array(String | Int32 | Bool | Array(String) | Time | Nil)) {
        cast_result(args[0]?.try(&.to_s.upcase) || "")
      }

      FUNCTIONS["lower"] = ->(args : Array(String | Int32 | Bool | Array(String) | Time | Nil)) {
        cast_result(args[0]?.try(&.to_s.downcase) || "")
      }

      FUNCTIONS["title"] = ->(args : Array(String | Int32 | Bool | Array(String) | Time | Nil)) {
        cast_result(args[0]?.try(&.to_s.split.map(&.capitalize).join(" ")) || "")
      }

      FUNCTIONS["trim"] = ->(args : Array(String | Int32 | Bool | Array(String) | Time | Nil)) {
        cast_result(args[0]?.try(&.to_s.strip) || "")
      }

      FUNCTIONS["slugify"] = ->(args : Array(String | Int32 | Bool | Array(String) | Time | Nil)) {
        str = args[0]?.try(&.to_s) || ""
        cast_result(str.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, ""))
      }
    end

    # ARRAY FUNCTIONS
    private def self.register_array_functions
      FUNCTIONS["len"] = ->(args : Array(String | Int32 | Bool | Array(String) | Time | Nil)) {
        case args[0]
        when Array then args[0].as(Array).size
        when String then args[0].as(String).size
        else 0
        end.as(String | Int32 | Bool | Array(String) | Time | Nil)
      }
    end

    # MATH FUNCTIONS
    private def self.register_math_functions
      FUNCTIONS["add"] = ->(args : Array(String | Int32 | Bool | Array(String) | Time | Nil)) {
        a = args[0]?.try(&.as(Int32)) || 0
        b = args[1]?.try(&.as(Int32)) || 0
        cast_result(a + b)
      }
    end

    # TIME FUNCTIONS
    private def self.register_time_functions
      FUNCTIONS["now"] = ->(args : Array(String | Int32 | Bool | Array(String) | Time | Nil)) {
        cast_result(Time.utc)
      }
    end

    # HASH FUNCTIONS
    private def self.register_hash_functions
      # Minimal implementation
    end

    # URL FUNCTIONS
    private def self.register_url_functions
      FUNCTIONS["urlize"] = ->(args : Array(String | Int32 | Bool | Array(String) | Time | Nil)) {
        str = args[0]?.try(&.to_s) || ""
        cast_result(str.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, ""))
      }
    end

    # LOGIC FUNCTIONS
    private def self.register_logic_functions
      FUNCTIONS["eq"] = ->(args : Array(String | Int32 | Bool | Array(String) | Time | Nil)) {
        cast_result(args[0] == args[1])
      }
    end

    # TYPE FUNCTIONS
    private def self.register_type_functions
      FUNCTIONS["string"] = ->(args : Array(String | Int32 | Bool | Array(String) | Time | Nil)) {
        cast_result(args[0]?.try(&.to_s) || "")
      }
    end
  end
end
