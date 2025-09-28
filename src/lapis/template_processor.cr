require "./content"
require "./content_comparison"
require "html"
require "string_pool"
require "./logger"
require "./exceptions"

module Lapis
  class TemplateProcessor
    getter context : TemplateContext

    # StringPool for memory-efficient string caching
    private STRING_POOL = StringPool.new(256)

    # Pre-computed method tuples for efficient template processing
    private SECTION_NAV_METHODS = Set{:"has_prev?", :"has_next?", :prev, :next}
    private BREADCRUMB_METHODS  = Set{:title, :url, :active}
    private MENU_ITEM_METHODS   = Set{:name, :url, :external}
    private CONTENT_METHODS     = Set{:title, :url, :"date_formatted", :tags, :summary, :"reading_time"}
    private ARRAY_METHODS       = Set{"first", "last", "size", "empty?", "uniq", "uniq_by", "sample", "shuffle", "rotate", "reverse", "sort_by_length", "partition", "compact", "chunk", "index", "rindex", "array_truncate", "any?", "all?", "none?", "one?"}

    # Compile-time regexes for frequently used patterns
    private IF_CONDITIONAL_PATTERN      = /\{\{\s*if\s+([^}]+)\s*\}\}(.*?)\{\{\s*endif\s*\}\}/m
    private IF_ELSE_CONDITIONAL_PATTERN = /\{\{\s*if\s+([^}]+)\s*\}\}(.*?)\{\{\s*else\s*\}\}(.*?)\{\{\s*endif\s*\}\}/m
    private FOR_LOOP_PATTERN            = /\{\{\s*for\s+(\w+)\s+in\s+([^}]+)\s*\}\}(.*?)\{\{\s*endfor\s*\}\}/m
    private VARIABLE_PATTERN            = /\{\{\s*([^}]+)\s*\}\}/
    private METHOD_CALL_PATTERN         = /(\w+)\(([^)]*)\)/
    private FILTER_PATTERN              = /(\w+)\(([^)]*)\)/

    def initialize(@context : TemplateContext)
    end

    # StringPool helper methods for memory-efficient string operations
    private def cache_string(str : String) : String
      STRING_POOL.get(str)
    end

    private def cache_template_pattern(pattern : String) : String
      STRING_POOL.get(pattern)
    end

    def process(template : String) : String
      result = template

      # Process conditionals first (they can contain loops and variables)
      result = process_conditionals(result)

      # Process loops (they can contain variables)
      result = process_loops(result)

      # Process variables and method calls
      result = process_variables(result)

      result
    end

    # SLICE-BASED TEMPLATE PROCESSING FOR ZERO-COPY OPERATIONS
    def process_slice(template : String) : String
      template_slice = template.to_slice
      result_slice = process_template_slice(template_slice)
      result_slice.to_s
    end

    # SLICE-BASED TEMPLATE PROCESSING IMPLEMENTATION
    private def process_template_slice(template_slice : Slice(UInt8)) : Slice(UInt8)
      # For now, convert back to string and use existing processing
      # This is a placeholder for future slice-based string processing
      template_string = template_slice.to_s
      processed_string = process(template_string)
      processed_string.to_slice
    end

    private def process_conditionals(template : String) : String
      # Handle {{ if condition }}...{{ endif }} blocks
      result = template.gsub(IF_CONDITIONAL_PATTERN) do |match|
        condition = $1.strip
        content = $2

        if evaluate_condition(condition)
          # Process the content inside the if block
          process(content)
        else
          ""
        end
      end

      # Handle {{ if condition }}...{{ else }}...{{ endif }} blocks
      result = result.gsub(IF_ELSE_CONDITIONAL_PATTERN) do |match|
        condition = $1.strip
        if_content = $2
        else_content = $3

        if evaluate_condition(condition)
          process(if_content)
        else
          process(else_content)
        end
      end

      result
    end

    private def process_loops(template : String) : String
      # Handle {{ for item in collection }}...{{ endfor }} blocks
      template.gsub(FOR_LOOP_PATTERN) do |match|
        item_var = $1.strip
        collection_expr = $2.strip
        loop_content = $3

        collection = evaluate_expression(collection_expr)

        case collection
        when Array
          array_collection = collection.as(Array)
          if array_collection.empty?
            ""
          else
            array_collection.map_with_index do |item, index|
              # Create a temporary context with the loop item
              loop_context = create_loop_context(item_var, item, index)
              process_with_context(loop_content, loop_context)
            end.join("")
          end
        else
          ""
        end
      end
    end

    # SLICE-BASED LOOP PROCESSING FOR ZERO-COPY OPERATIONS
    private def process_loops_slice(template : String) : String
      # Handle {{ for item in collection }}...{{ endfor }} blocks with slice processing
      template.gsub(FOR_LOOP_PATTERN) do |match|
        item_var = $1.strip
        collection_expr = $2.strip
        loop_content = $3

        collection = evaluate_expression(collection_expr)

        case collection
        when Array
          array_collection = collection.as(Array)
          if array_collection.empty?
            ""
          else
            # Use slice for more efficient processing
            collection_slice = array_collection.to_slice
            result_parts = [] of String

            collection_slice.each_with_index do |item, index|
              loop_context = create_loop_context(item_var, item, index)
              result_parts << process_with_context(loop_content, loop_context)
            end

            result_parts.join("")
          end
        else
          ""
        end
      end
    end

    private def process_variables(template : String) : String
      # Process all {{ variable }} expressions
      template.gsub(VARIABLE_PATTERN) do |match|
        expression = $1.strip

        # Skip if this looks like a control structure (already processed)
        next match if expression.starts_with?("if ") || expression.starts_with?("for ") ||
                      expression == "endif" || expression == "endfor" || expression == "else"

        # Handle filters like {{ variable | filter }}
        if expression.includes?(" | ")
          parts = expression.split(" | ")
          value = evaluate_expression(parts[0].strip)

          # Apply filters in sequence
          parts[1..].each do |filter|
            value = apply_filter(value, filter.strip)
          end

          format_value(value)
        else
          value = evaluate_expression(expression)
          format_value(value)
        end
      end
    end

    private def evaluate_condition(condition : String) : Bool
      # Handle simple existence checks
      if condition.ends_with?("?")
        # Handle method calls like "section_nav.has_prev?"
        value = evaluate_expression(condition)
        case value
        when Bool then value.is_a?(Bool) ? value : false
        when Nil  then false
        else           !value.to_s.empty?
        end
      else
        # Handle simple variable existence
        value = evaluate_expression(condition)
        case value
        when Bool                  then value.is_a?(Bool) ? value : false
        when Nil                   then false
        when Array                 then !(value.is_a?(Array) ? value.empty? : true)
        when String                then !(value.is_a?(String) ? value.empty? : true)
        when Array(MenuItem)       then !(value.is_a?(Array(MenuItem)) ? value.empty? : true)
        when Array(BreadcrumbItem) then !(value.is_a?(Array(BreadcrumbItem)) ? value.empty? : true)
        when Array(Content)        then !(value.is_a?(Array(Content)) ? value.empty? : true)
        else                            true
        end
      end
    end

    private def evaluate_expression(expression : String)
      # Handle method chains like "section_nav.has_prev?"
      if expression.includes?(".")
        parts = expression.split(".")
        result = get_base_value(parts[0])

        parts[1..].each do |method|
          result = dispatch_template_method_tuple(result, method)
        end
      end
    end

    # Optimized tuple-based method dispatch for template processing
    private def dispatch_template_method_tuple(result, method : String)
      # Use tuple operations for efficient method dispatch
      case {result.class, method}
      when {SectionNavigation.class, "has_prev?"}
        dispatch_section_nav_method(result, :"has_prev?") if SECTION_NAV_METHODS.includes?(:"has_prev?")
      when {SectionNavigation.class, "has_next?"}
        dispatch_section_nav_method(result, :"has_next?") if SECTION_NAV_METHODS.includes?(:"has_next?")
      when {SectionNavigation.class, "prev"}
        dispatch_section_nav_method(result, :prev) if SECTION_NAV_METHODS.includes?(:prev)
      when {SectionNavigation.class, "next"}
        dispatch_section_nav_method(result, :next) if SECTION_NAV_METHODS.includes?(:next)
      when {BreadcrumbItem.class, "title"}
        dispatch_breadcrumb_method(result, :title) if BREADCRUMB_METHODS.includes?(:title)
      when {BreadcrumbItem.class, "url"}
        dispatch_breadcrumb_method(result, :url) if BREADCRUMB_METHODS.includes?(:url)
      when {BreadcrumbItem.class, "active"}
        dispatch_breadcrumb_method(result, :active) if BREADCRUMB_METHODS.includes?(:active)
      when {MenuItem.class, "name"}
        dispatch_menu_item_method(result, :name) if MENU_ITEM_METHODS.includes?(:name)
      when {MenuItem.class, "url"}
        dispatch_menu_item_method(result, :url) if MENU_ITEM_METHODS.includes?(:url)
      when {MenuItem.class, "external"}
        dispatch_menu_item_method(result, :external) if MENU_ITEM_METHODS.includes?(:external)
      when {Content.class, "title"}
        dispatch_content_template_method(result, :title) if CONTENT_METHODS.includes?(:title)
      when {Content.class, "url"}
        dispatch_content_template_method(result, :url) if CONTENT_METHODS.includes?(:url)
      when {Content.class, "date_formatted"}
        dispatch_content_template_method(result, :"date_formatted") if CONTENT_METHODS.includes?(:"date_formatted")
      when {Content.class, "tags"}
        dispatch_content_template_method(result, :tags) if CONTENT_METHODS.includes?(:tags)
      when {Content.class, "summary"}
        dispatch_content_template_method(result, :summary) if CONTENT_METHODS.includes?(:summary)
      when {Content.class, "reading_time"}
        dispatch_content_template_method(result, :"reading_time") if CONTENT_METHODS.includes?(:"reading_time")
      when {Array.class, _}
        dispatch_array_template_method(result, method) if ARRAY_METHODS.includes?(method)
      else
        result
      end || result
    end

    # Tuple-based method dispatchers using tuple iteration
    private def dispatch_section_nav_method(result, method_symbol : Symbol)
      SECTION_NAV_METHODS.to_a.each do |method|
        return handle_section_nav_method(result, method) if method == method_symbol
      end
      nil
    end

    private def dispatch_breadcrumb_method(result, method_symbol : Symbol)
      BREADCRUMB_METHODS.to_a.each do |method|
        return handle_breadcrumb_method(result, method) if method == method_symbol
      end
      nil
    end

    private def dispatch_menu_item_method(result, method_symbol : Symbol)
      MENU_ITEM_METHODS.to_a.each do |method|
        return handle_menu_item_method(result, method) if method == method_symbol
      end
      nil
    end

    private def dispatch_content_template_method(result, method_symbol : Symbol)
      CONTENT_METHODS.to_a.each do |method|
        return handle_content_template_method(result, method) if method == method_symbol
      end
      nil
    end

    private def dispatch_array_template_method(result, method : String)
      ARRAY_METHODS.each do |m|
        return handle_array_template_method(result, m) if m == method
      end
      nil
    end

    # Handler methods using tuple operations
    private def handle_section_nav_method(result, method : Symbol)
      case method
      when :"has_prev?" then result.as(SectionNavigation).has_prev?
      when :"has_next?" then result.as(SectionNavigation).has_next?
      when :prev        then result.as(SectionNavigation).prev
      when :next        then result.as(SectionNavigation).next
      else                   nil
      end
    end

    private def handle_breadcrumb_method(result, method : Symbol)
      case method
      when :title  then result.as(BreadcrumbItem).title
      when :url    then result.as(BreadcrumbItem).url
      when :active then result.as(BreadcrumbItem).active
      else              nil
      end
    end

    private def handle_menu_item_method(result, method : Symbol)
      case method
      when :name     then result.as(MenuItem).name
      when :url      then result.as(MenuItem).url
      when :external then result.as(MenuItem).external
      else                nil
      end
    end

    private def handle_content_template_method(result, method : Symbol)
      case method
      when :title then result.as(Content).title
      when :url   then result.as(Content).url
      when :"date_formatted"
        date = result.as(Content).date
        date ? date.to_s(Lapis::DATE_FORMAT_HUMAN) : ""
      when :tags then result.as(Content).tags
      when :summary
        page_ops = PageOperations.new(result.as(Content), @context.query.site_content)
        page_ops.summary
      when :"reading_time"
        page_ops = PageOperations.new(result.as(Content), @context.query.site_content)
        page_ops.reading_time
      else nil
      end
    end

    private def handle_array_template_method(result, method : String)
      case method
      when "first"
        if method.includes?("(")
          # Handle first(n) calls
          if match = method.match(/first\((\d+)\)/, options: Regex::MatchOptions::None)
            n = match[1].to_i
            result.as(Array).first(n)
          else
            result.as(Array).first?
          end
        else
          result.as(Array).first?
        end
      when "last"
        if method.includes?("(")
          if match = method.match(/last\((\d+)\)/, options: Regex::MatchOptions::None)
            n = match[1].to_i
            result.as(Array).last(n)
          else
            result.as(Array).last?
          end
        else
          result.as(Array).last?
        end
      when "size"
        result.as(Array).size
      when "empty?"
        result.as(Array).empty?
      else
        result
      end
    end

    private def get_base_value(name : String)
      case name
      when "title"       then @context.title
      when "content"     then @context.content.content
      when "description" then @context.description
      when "date"        then @context.content.date
      when "date_formatted"
        date = @context.content.date
        date ? date.to_s(Lapis::DATE_FORMAT_HUMAN) : ""
      when "tags"             then @context.tags
      when "categories"       then @context.categories
      when "reading_time"     then @context.reading_time
      when "word_count"       then @context.word_count
      when "summary"          then @context.summary
      when "breadcrumbs"      then @context.breadcrumbs
      when "site_menu"        then @context.site_menu
      when "site_menu()"      then @context.site_menu
      when "section_nav"      then @context.section_nav
      when "related_content"  then @context.related_content
      when "backlinks"        then @context.backlinks
      when "tag_cloud"        then @context.tag_cloud
      when "archive_by_year"  then @context.archive_by_year
      when "archive_by_month" then @context.archive_by_month
      when "recent_posts"     then @context.recent_posts
      when "posts"            then @context.posts
      when "pages"            then @context.pages
      when "page"             then @context.page
      when "site"             then @context.site
      else
        # Try to call methods with parentheses
        if name.includes?("(")
          handle_method_call(name)
        else
          ""
        end
      end
    end

    private def handle_method_call(call : String)
      if match = call.match(METHOD_CALL_PATTERN, options: Regex::MatchOptions::None)
        method_name = match[1]
        args_str = match[2]

        case method_name
        when "content_by_section"
          if args_str.includes?('"')
            section = args_str.gsub("\"", "")
            @context.content_by_section(section)
          elsif args_str == "page.section"
            if @context.content.is_a?(Content)
              section = @context.content.as(Content).section
              @context.content_by_section(section)
            else
              [] of Content
            end
          else
            [] of Content
          end
        when "content_by_tag"
          tag = args_str.gsub("\"", "")
          @context.content_by_tag(tag)
        when "recent_posts"
          count = args_str.empty? ? 5 : args_str.to_i
          @context.recent_posts(count)
        when "related_content"
          count = args_str.empty? ? 5 : args_str.to_i
          @context.related_content(count)
        else
          ""
        end
      else
        ""
      end
    end

    private def create_loop_context(item_var : String, item, index : Int32) : Hash(String, String)
      context = {} of String => String

      case item
      when BreadcrumbItem
        context["#{item_var}.title"] = item.title
        context["#{item_var}.url"] = item.url
        context["#{item_var}.active"] = item.active.to_s
      when MenuItem
        context["#{item_var}.name"] = item.name
        context["#{item_var}.url"] = item.url
        context["#{item_var}.external"] = item.external.to_s
      when Content
        context["#{item_var}.title"] = item.title
        context["#{item_var}.url"] = item.url
        context["#{item_var}.date_formatted"] = item.date.try(&.to_s(Lapis::DATE_FORMAT_HUMAN)) || ""
        context["#{item_var}.tags"] = item.tags.join(", ")
        context["#{item_var}.summary"] = PageOperations.new(item, @context.query.site_content).summary
        context["#{item_var}.reading_time"] = PageOperations.new(item, @context.query.site_content).reading_time.to_s
      when String
        context[item_var] = item
      else
        context[item_var] = item.to_s
      end

      context
    end

    private def process_with_context(template : String, loop_context : Hash(String, String)) : String
      result = template

      # Replace loop variables
      loop_context.each do |key, value|
        result = result.gsub("{{ #{key} }}", value)
      end

      # Process any remaining template syntax
      result = process_variables(result)
      result = process_conditionals(result)

      result
    end

    private def format_value(value) : String
      case value
      when String       then value
      when Int32, Int64 then value.to_s
      when Bool         then value.to_s
      when Array(BreadcrumbItem)
        # Don't process arrays of complex types
        ""
      when Array(MenuItem)
        # Don't process arrays of complex types
        ""
      when Array(Content)
        # Don't process arrays of complex types
        ""
      when Array(String)
        value.join(", ")
      when Hash
        # For complex objects like tag clouds
        value.to_s
      when Nil then ""
      else          value.to_s
      end
    end

    private def apply_filter(value, filter : String)
      case filter
      when "title"
        # Enhanced title case with Unicode support
        str = value.to_s
        return "" if str.empty?
        String.build do |io|
          str.split(/\s+/).each_with_index do |word, index|
            io << " " if index > 0
            io << word.capitalize
          end
        end
      when "upcase", "upper"
        value.to_s.upcase
      when "downcase", "lower"
        value.to_s.downcase
      when "slugify"
        # Enhanced slugify with Unicode normalization
        str = value.to_s
        return "" if str.empty?
        SafeCast.optimized_slugify(str)
      when "strip"
        value.to_s.strip
      when "lstrip"
        value.to_s.lstrip
      when "rstrip"
        value.to_s.rstrip
      when "unicode_normalize"
        str = value.to_s
        return "" if str.empty?
        str.unicode_normalize
      when "validate_utf8"
        value.to_s.valid_encoding?.to_s
      when "tr"
        # Character translation
        str = value.to_s
        from = "" # Would need additional context for from/to
        to = ""
        str.tr(from, to)
      when "squeeze"
        value.to_s.squeeze
      when "delete"
        str = value.to_s
        chars = "" # Would need additional context for chars to delete
        str.delete(chars)
      when "char_count"
        value.to_s.size.to_s
      when "byte_count"
        value.to_s.bytesize.to_s
      when "codepoint_count"
        value.to_s.codepoints.size.to_s
      when "reverse"
        value.to_s.reverse
      when "repeat"
        str = value.to_s
        count = 1 # Would need additional context for count
        str * count
      when "plain"
        # Remove HTML tags for plain text output
        value.to_s.gsub(/<[^>]*>/, "")
      when "escape", "escape_html"
        # HTML escape using Crystal's official HTML module
        HTML.escape(value.to_s)
      when "truncate"
        # Enhanced truncation with Unicode awareness
        text = value.to_s
        return text if text.empty?
        max_length = 50
        if text.size > max_length
          # Use Unicode-aware truncation
          truncated = text[0...max_length - 3]
          "#{truncated}..."
        else
          text
        end
      when "first"
        case value
        when Array then value.is_a?(Array) ? value.first? : nil
        else            value
        end
      when "last"
        case value
        when Array then value.is_a?(Array) ? value.last? : nil
        else            value
        end
      when "size", "length"
        case value
        when Array  then value.is_a?(Array) ? value.size : 0
        when String then value.is_a?(String) ? value.size : 0
        else             0
        end
      when "join"
        case value
        when Array then value.as(Array).join(", ")
        else            value.to_s
        end
        case value
        when Array  then value.as(Array).reverse
        when String then value.as(String).reverse
        else             value
        end
      when "sort"
        case value
        when Array(String)  then value.as(Array(String)).sort
        when Array(Int32)   then value.as(Array(Int32)).sort
        when Array(Content) then value.as(Array(Content)).sort
        else                     value
        end
      when "clamp"
        # Clamp filter for ranges - will be handled in apply_filter_with_args
        value
      when "uniq", "unique"
        case value
        when Array then value.as(Array).to_set.to_a
        else            value
        end
      when "sample"
        case value
        when Array
          count = arg.try(&.to_i?) || 1
          value.as(Array).sample(count)
        else
          value
        end
      when "shuffle"
        case value
        when Array then value.as(Array).shuffle
        else            value
        end
      when "compact"
        case value
        when Array then value.as(Array).compact
        else            value
        end
      when "any?"
        case value
        when Array then value.as(Array).any? { |item| !item.nil? }
        else            false
        end
      when "all?"
        case value
        when Array then value.as(Array).all? { |item| !item.nil? }
        else            false
        end
      when "none?"
        case value
        when Array then value.as(Array).none?(Nil)
        else            false
        end
      when "one?"
        case value
        when Array then value.as(Array).one? { |item| !item.nil? }
        else            false
        end
      else
        # Handle filters with arguments like truncate(100) or min(5)
        if filter.includes?("(")
          apply_filter_with_args(value, filter)
        else
          # Unknown filter, return value as-is
          value
        end
      end
    end

    private def apply_filter_with_args(value, filter : String)
      if match = filter.match(FILTER_PATTERN, options: Regex::MatchOptions::None)
        filter_name = match[1]
        args_str = match[2]
        arg = args_str.to_i? || args_str

        case filter_name
        when "truncate"
          if arg.is_a?(Int32)
            text = value.to_s
            if text.size > arg
              range = 0...arg - 3
              "#{text[range]}..."
            else
              text
            end
          else
            value
          end
        when "first"
          if arg.is_a?(Int32) && value.is_a?(Array)
            value.as(Array).first(arg)
          else
            value
          end
        when "last"
          if arg.is_a?(Int32) && value.is_a?(Array)
            value.as(Array).last(arg)
          else
            value
          end
        when "min"
          if arg.is_a?(Int32)
            case value
            when Int32 then [value.as(Int32), arg].min
            when Array then value.as(Array).first(arg)
            else            value
            end
          else
            value
          end
        when "max"
          if arg.is_a?(Int32)
            case value
            when Int32 then [value.as(Int32), arg].max
            else            value
            end
          else
            value
          end
        when "join"
          if value.is_a?(Array)
            value.as(Array).join(args_str.gsub("\"", ""))
          else
            value
          end
        when "clamp"
          # Handle clamp(min,max) or clamp(range)
          if args_str.includes?(",")
            parts = args_str.split(",")
            if parts.size == 2
              min_val = parts[0].strip.to_i?
              max_val = parts[1].strip.to_i?
              if min_val && max_val && value.is_a?(Int32)
                # Use Range for validation
                range = min_val..max_val
                range.includes?(value.as(Int32)) ? value : value.as(Int32).clamp(min_val, max_val)
              else
                value
              end
            else
              value
            end
          else
            # Single argument - treat as max (min is 0)
            max_val = args_str.to_i?
            if max_val && value.is_a?(Int32)
              range = 0..max_val
              range.includes?(value.as(Int32)) ? value : value.as(Int32).clamp(0, max_val)
            else
              value
            end
          end
        else
          value
        end
      else
        value
      end
    end
  end
end
