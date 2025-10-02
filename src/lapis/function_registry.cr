require "./shared_string_pool"
require "./string_functions"
require "./array_functions"
require "./math_functions"
require "./time_functions"
require "./hash_functions"
require "./url_functions"
require "./logic_functions"
require "./type_functions"
require "./markdown_functions"
require "./text_functions"
require "./file_functions"

module Lapis
  # Core function registry system for managing function registration and lookup
  class FunctionRegistry
    # Function registry - comprehensive function system using symbols for performance
    FUNCTIONS = {} of Symbol => Proc(Array(String), String)

    # Function arity registry for automatic validation
    FUNCTION_ARITY = {} of Symbol => Int32

    # Use shared StringPool for memory efficiency
    STRING_POOL = SharedStringPool.instance

    # Function result cache for pure functions (no side effects)
    FUNCTION_CACHE = {} of String => String

    # Cache size limit to prevent memory bloat
    MAX_CACHE_SIZE = 1000

    # Register all function categories
    def self.setup
      # Re-enable function registration
      StringFunctions.register_functions
      ArrayFunctions.register_functions
      MathFunctions.register_functions
      TimeFunctions.register_functions
      HashFunctions.register_functions
      UrlFunctions.register_functions
      LogicFunctions.register_functions
      TypeFunctions.register_functions
      MarkdownFunctions.register_functions
      TextFunctions.register_functions
      FileFunctions.register_functions
    end

    def self.call(name : String, args : Array(String)) : String
      symbol_name = string_to_symbol(name)
      return "" unless symbol_name

      if func = FUNCTIONS[symbol_name]?
        # Automatic arity validation using FUNCTION_ARITY registry
        expected_arity = FUNCTION_ARITY[symbol_name]?
        if expected_arity && expected_arity != args.size
          # Special case for date function - allow 0 or 1 arguments
          if symbol_name == :date && args.size == 0
            # Allow date() with no arguments
            # Special case for variable arity functions (arity 0 means variable)
          elsif expected_arity == 0
            # Allow any number of arguments for variable arity functions
          else
            raise ArgumentError.new("#{name} expects #{expected_arity} argument#{expected_arity == 1 ? "" : "s"}, got #{args.size}")
          end
        end

        # Check if this function can be cached (pure functions only)
        if cacheable_function?(symbol_name)
          cache_key = "#{name}:#{args.join("|")}"
          if cached_result = FUNCTION_CACHE[cache_key]?
            return cached_result
          end

          # Execute function and cache result
          result = func.call(args)

          # Manage cache size
          if FUNCTION_CACHE.size >= MAX_CACHE_SIZE
            FUNCTION_CACHE.clear # Simple eviction strategy
          end

          FUNCTION_CACHE[cache_key] = result
          result
        else
          # Non-cacheable function (has side effects like time functions)
          func.call(args)
        end
      else
        ""
      end
    end

    def self.function_list : Array(String)
      FUNCTIONS.keys.map(&.to_s)
    end

    def self.has_function?(name : String) : Bool
      symbol_name = string_to_symbol(name)
      return false unless symbol_name
      FUNCTIONS.has_key?(symbol_name)
    end

    # Helper method to register function with arity
    def self.register_function(name : Symbol, arity : Int32, &block : Array(String) -> String)
      FUNCTIONS[name] = ->(args : Array(String)) : String { block.call(args) }
      FUNCTION_ARITY[name] = arity
    end

    # High-performance string to symbol lookup using Hash
    private STRING_TO_SYMBOL_MAP = {
      "upper"                 => :upper,
      "lower"                 => :lower,
      "title"                 => :title,
      "trim"                  => :trim,
      "lstrip"                => :lstrip,
      "rstrip"                => :rstrip,
      "chomp"                 => :chomp,
      "slugify"               => :slugify,
      "camelize"              => :camelize,
      "underscore"            => :underscore,
      "dasherize"             => :dasherize,
      "unicode_normalize"     => :unicode_normalize,
      "validate_utf8"         => :validate_utf8,
      "tr"                    => :tr,
      "squeeze"               => :squeeze,
      "delete"                => :delete,
      "char_count"            => :char_count,
      "byte_count"            => :byte_count,
      "codepoint_count"       => :codepoint_count,
      "to_utf16"              => :to_utf16,
      "reverse"               => :reverse,
      "repeat"                => :repeat,
      "build_string"          => :build_string,
      "pluralize"             => :pluralize,
      "singularize"           => :singularize,
      "truncate"              => :truncate,
      "truncatewords"         => :"truncatewords",
      "strip_newlines"        => :"strip_newlines",
      "newline_to_br"         => :"newline_to_br",
      "escape"                => :escape,
      "unescape"              => :unescape,
      "len"                   => :len,
      "add"                   => :add,
      "subtract"              => :subtract,
      "multiply"              => :multiply,
      "divide"                => :divide,
      "modulo"                => :modulo,
      "round"                 => :round,
      "ceil"                  => :ceil,
      "floor"                 => :floor,
      "abs"                   => :abs,
      "sqrt"                  => :sqrt,
      "pow"                   => :pow,
      "min"                   => :min,
      "max"                   => :max,
      "sum"                   => :sum,
      "now"                   => :now,
      "date"                  => :date,
      "time"                  => :time,
      "datetime"              => :datetime,
      "timestamp"             => :timestamp,
      "rfc3339"               => :rfc3339,
      "iso8601"               => :iso8601,
      "ago"                   => :ago,
      "time_ago"              => :"time_ago",
      "has_key"               => :"has_key",
      "keys"                  => :keys,
      "values"                => :values,
      "urlize"                => :urlize,
      "relative_url"          => :"relative_url",
      "absolute_url"          => :"absolute_url",
      "url_encode"            => :"url_encode",
      "url_decode"            => :"url_decode",
      "url_normalize"         => :"url_normalize",
      "url_scheme"            => :"url_scheme",
      "url_host"              => :"url_host",
      "url_port"              => :"url_port",
      "url_path"              => :"url_path",
      "url_query"             => :"url_query",
      "url_fragment"          => :"url_fragment",
      "is_absolute_url"       => :"is_absolute_url",
      "is_valid_url"          => :"is_valid_url",
      "url_join"              => :"url_join",
      "url_components"        => :"url_components",
      "query_params"          => :"query_params",
      "update_query_param"    => :"update_query_param",
      "eq"                    => :eq,
      "ne"                    => :ne,
      "gt"                    => :gt,
      "lt"                    => :lt,
      "gte"                   => :gte,
      "lte"                   => :lte,
      "and"                   => :and,
      "or"                    => :or,
      "not"                   => :not,
      "contains"              => :contains,
      "starts_with"           => :"starts_with",
      "ends_with"             => :"ends_with",
      "string"                => :string,
      "int"                   => :int,
      "float"                 => :float,
      "bool"                  => :bool,
      "array"                 => :array,
      "size"                  => :size,
      "empty"                 => :empty,
      "blank"                 => :blank,
      "markdownify"           => :markdownify,
      "strip_html"            => :"strip_html",
      "escape_html"           => :"escape_html",
      "unescape_html"         => :"unescape_html",
      "word_count"            => :"word_count",
      "reading_time"          => :"reading_time",
      "first"                 => :first,
      "last"                  => :last,
      "replace"               => :replace,
      "remove"                => :remove,
      "file_exists"           => :"file_exists",
      "file_size"             => :"file_size",
      "file_extension"        => :"file_extension",
      "file_extname"          => :"file_extname",
      "file_basename"         => :"file_basename",
      "file_dirname"          => :"file_dirname",
      "char_count_alpha"      => :"char_count_alpha",
      "char_count_digit"      => :"char_count_digit",
      "char_count_upper"      => :"char_count_upper",
      "char_count_lower"      => :"char_count_lower",
      "char_count_whitespace" => :"char_count_whitespace",
      "extract_digits"        => :"extract_digits",
      "extract_letters"       => :"extract_letters",
      "is_numeric"            => :"is_numeric",
      "is_alpha"              => :"is_alpha",
      "is_alphanumeric"       => :"is_alphanumeric",
      "starts_with_upper"     => :"starts_with_upper",
      "uniq"                  => :uniq,
      "uniq_by"               => :"uniq_by",
      "sample"                => :sample,
      "shuffle"               => :shuffle,
      "rotate"                => :rotate,
      "sort_by_length"        => :"sort_by_length",
      "partition"             => :partition,
      "compact"               => :compact,
      "chunk"                 => :chunk,
      "index"                 => :index,
      "rindex"                => :rindex,
      "array_truncate"        => :"array_truncate",
    } of String => Symbol

    # Convert string to symbol for lookup using O(1) Hash lookup
    private def self.string_to_symbol(name : String) : Symbol?
      STRING_TO_SYMBOL_MAP[name]?
    end

    # Determine if a function can be cached (pure functions with no side effects)
    private def self.cacheable_function?(symbol_name : Symbol) : Bool
      # Time-based functions are not cacheable as they change over time
      non_cacheable = Set{
        :now, :date, :time, :datetime, :timestamp, :rfc3339, :iso8601, :ago, :"time_ago",
      }

      # File system functions are not cacheable as files may change
      file_functions = Set{
        :"file_exists", :"file_size", :"file_extension", :"file_extname",
        :"file_basename", :"file_dirname",
      }

      !non_cacheable.includes?(symbol_name) && !file_functions.includes?(symbol_name)
    end

    # Clear the function cache (useful for testing or memory management)
    def self.clear_cache
      FUNCTION_CACHE.clear
    end

    # Get cache statistics
    def self.cache_stats : Hash(String, Int32)
      {
        "cache_size"     => FUNCTION_CACHE.size,
        "max_cache_size" => MAX_CACHE_SIZE,
        "cache_hit_rate" => 0, # Would need hit/miss tracking for real stats
      }
    end
  end
end
