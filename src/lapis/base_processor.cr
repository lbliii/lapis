require "./template_patterns"
require "./template_methods"
require "./shared_string_pool"
require "./logger"
require "./exceptions"

module Lapis
  # Base processor class that provides common functionality for all template processors
  # This eliminates code duplication between TemplateProcessor and FunctionProcessor
  abstract class BaseProcessor
    include TemplatePatterns
    include TemplateMethods

    getter context : TemplateContext
    getter string_pool : SharedStringPool

    def initialize(@context : TemplateContext)
      @string_pool = SharedStringPool.instance
      setup_shared_resources
    end

    # Abstract method that must be implemented by subclasses
    abstract def process(template : String) : String

    protected def setup_shared_resources
      # Common initialization logic for all processors
      Logger.debug("Initializing processor", processor: self.class.name)
    end

    # Shared string caching utility
    protected def cache_string(str : String) : String
      @string_pool.get(str)
    end

    # Shared value formatting with string caching
    protected def format_value(value) : String
      case value
      when String
        cache_string(value)
      when Int32, Int64
        cache_string(value.to_s)
      when Bool
        cache_string(value.to_s)
      when Time
        cache_string(value.to_s("%Y-%m-%d"))
      when Array(String)
        cache_string(value.join(", "))
      when Array
        cache_string(value.size.to_s) # For other arrays, show count
      when Nil
        ""
      else
        cache_string(value.to_s)
      end
    end

    # Shared condition evaluation logic
    protected def evaluate_condition(condition : String) : Bool
      # Handle function calls in conditions
      if condition.includes?("(")
        value = evaluate_expression(condition)
        case value
        when Bool   then value.as(Bool)
        when Nil    then false
        when Array  then !value.as(Array).empty?
        when String then !value.as(String).empty?
        when Int32  then value.as(Int32) != 0
        else             true
        end
      else
        # Simple variable check
        value = evaluate_expression(condition)
        case value
        when Bool   then value.as(Bool)
        when Nil    then false
        when Array  then !value.as(Array).empty?
        when String then !value.as(String).empty?
        else             true
        end
      end
    end

    # Shared expression evaluation (to be overridden by subclasses for specific behavior)
    protected def evaluate_expression(expression : String)
      # Default implementation - subclasses should override with specific logic
      Logger.debug("Evaluating expression", expression: expression)
      nil
    end

    # Shared method dispatch using centralized method sets
    protected def dispatch_method_by_type(object, method : Symbol)
      case object
      when Site
        dispatch_site_method(object, method) if valid_site_method?(method)
      when Page
        dispatch_page_method(object, method) if valid_page_method?(method)
      when Content
        dispatch_content_method(object, method) if valid_content_method?(method)
      when Time
        dispatch_time_method(object, method) if valid_time_method?(method)
      when Array
        dispatch_array_method(object, method) if valid_array_method?(method.to_s)
      else
        nil
      end
    end

    # Template cleanup utilities
    protected def cleanup_remaining_syntax(template : String) : String
      result = template

      # Remove any remaining unmatched template blocks
      result = result.gsub(ENDFOR_PATTERN, "")
      result = result.gsub(ENDIF_PATTERN, "")
      result = result.gsub(ELSE_PATTERN, "")
      result = result.gsub(END_PATTERN, "")

      # Remove any remaining template fragments or malformed syntax
      result = result.gsub(MALFORMED_FOR_PATTERN, "")
      result = result.gsub(MALFORMED_IF_PATTERN, "")

      # Final pass: remove any remaining {{ }} blocks that weren't processed
      result = result.gsub(REMAINING_TEMPLATE_PATTERN, "")

      # Clean up any resulting empty lines or malformed HTML
      result = result.gsub(EMPTY_TAG_PATTERN, "><")
      result = result.gsub(EMPTY_TAG_NEWLINE_PATTERN, ">\n")
      result = result.gsub(EMPTY_TAG_END_PATTERN, ">")

      result
    end

    # Shared error handling for template processing
    protected def handle_template_error(error : Exception, template : String, context_info : String = "")
      error_msg = "Template processing error: #{error.message}"
      error_msg += " (#{context_info})" unless context_info.empty?

      Logger.error(error_msg,
        template_preview: template[0, [100, template.size].min],
        error_class: error.class.name
      )

      # Return safe fallback
      ""
    end

    # Performance monitoring utilities
    protected def time_operation(operation_name : String, &)
      start_time = Time.monotonic
      Logger.debug("Starting operation", operation: operation_name)

      begin
        result = yield
        duration = Time.monotonic - start_time
        Logger.debug("Completed operation",
          operation: operation_name,
          duration: "#{duration.total_milliseconds.round(2)}ms"
        )
        result
      rescue ex
        duration = Time.monotonic - start_time
        Logger.error("Failed operation",
          operation: operation_name,
          duration: "#{duration.total_milliseconds.round(2)}ms",
          error: ex.message
        )
        raise ex
      end
    end

    # Abstract method dispatchers - to be implemented by subclasses
    protected abstract def dispatch_site_method(object, method : Symbol)
    protected abstract def dispatch_page_method(object, method : Symbol)
    protected abstract def dispatch_content_method(object, method : Symbol)
    protected abstract def dispatch_time_method(object, method : Symbol)
    protected abstract def dispatch_array_method(object, method : Symbol)

    # Get processor statistics
    def stats : NamedTuple(string_pool_size: Int32, processor_type: String)
      {
        string_pool_size: @string_pool.size,
        processor_type:   self.class.name,
      }
    end

    # Clear processor caches (useful for testing)
    def clear_caches
      @string_pool.clear
      Logger.debug("Cleared processor caches", processor: self.class.name)
    end
  end
end
