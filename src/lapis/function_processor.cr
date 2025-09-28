require "./functions"
require "./site"
require "./page"
require "./navigation"

module Lapis
  # Enhanced template processor with advanced functions
  class FunctionProcessor
    getter context : TemplateContext
    getter site : Site
    getter page : Page?

    def initialize(@context : TemplateContext)
      @site = Site.new(@context.config, @context.query.site_content)

      if @context.content.is_a?(Content)
        @page = Page.new(@context.content.as(Content), @site)
      end

      # Initialize global functions
      Functions.setup
    end

    def process(template : String) : String
      result = template

      # Process function calls first (they can be inside conditionals/loops)
      result = process_function_calls(result)

      # Process loops before conditionals (inner structures first)
      result = process_loops(result)

      # Process conditionals after loops
      result = process_conditionals(result)

      # Process simple variable substitutions
      result = process_variables(result)

      # Clean up any remaining template syntax (safety net)
      result = cleanup_remaining_syntax(result)

      result
    end

    private def process_function_calls(template : String) : String
      # Process {{ function(args) }} calls
      template.gsub(/\{\{\s*(\w+)\s*\(([^)]*)\)\s*\}\}/) do |match|
        function_name = $1
        args_str = $2

        # Parse arguments
        args = parse_function_args(args_str)

        if Functions.has_function?(function_name)
          result = Functions.call(function_name, args)
          format_value(result)
        else
          # Unknown function - return empty
          ""
        end
      end
    end

    private def process_conditionals(template : String) : String
      # Handle if/else/endif conditionals with proper nesting support
      # Use a more robust approach that handles nested blocks
      result = template

      # Keep processing conditionals until no more are found (handles nesting)
      loop do
        original_result = result

        result = result.gsub(/\{\{\s*if\s+([^}]+)\s*\}\}(.*?)\{\{\s*endif\s*\}\}/m) do |match|
          condition = $1.strip
          content = $2

          # Check if there's an else clause
          if content.includes?("{{ else }}")
            # Find the correct else - account for nested if/endif blocks
            else_pos = find_matching_else(content)
            if else_pos
              if_content = content[0...else_pos]
              else_content = content[else_pos + 10..-1] # Skip "{{ else }}"
            else
              # Fallback to simple split if we can't find matching else
              parts = content.split("{{ else }}", 2)
              if_content = parts[0]
              else_content = parts[1]? || ""
            end

            if evaluate_condition(condition)
              process(if_content) # Recursively process the if content
            else
              process(else_content) # Recursively process the else content
            end
          else
            if evaluate_condition(condition)
              process(content) # Recursively process the content
            else
              ""
            end
          end
        end

        # Break if no changes were made (no more conditionals to process)
        break if result == original_result
      end

      result
    end

    # Find the matching {{ else }} for an if block, accounting for nested if/endif
    private def find_matching_else(content : String) : Int32?
      else_pattern = /\{\{\s*else\s*\}\}/
      if_pattern = /\{\{\s*if\s+[^}]+\s*\}\}/
      endif_pattern = /\{\{\s*endif\s*\}\}/

      pos = 0
      nesting_level = 0

      while pos < content.size
        # Find the next occurrence of if, else, or endif
        if_match = content.match(if_pattern, pos)
        else_match = content.match(else_pattern, pos)
        endif_match = content.match(endif_pattern, pos)

        # Find which comes first
        next_if = if_match ? if_match.begin(0) : Int32::MAX
        next_else = else_match ? else_match.begin(0) : Int32::MAX
        next_endif = endif_match ? endif_match.begin(0) : Int32::MAX

        if next_if < next_else && next_if < next_endif
          # Found nested if
          nesting_level += 1
          pos = next_if + if_match.not_nil![0].size
        elsif next_endif < next_else
          # Found endif
          if nesting_level == 0
            break # This endif closes our block, no else found
          else
            nesting_level -= 1
            pos = next_endif + endif_match.not_nil![0].size
          end
        else
          # Found else
          if nesting_level == 0
            return next_else # This is our matching else
          else
            pos = next_else + else_match.not_nil![0].size
          end
        end
      end

      nil
    end

    private def process_loops(template : String) : String
      # Handle {{ range collection }} loops
      result = template.gsub(/\{\{\s*range\s+([^}]+)\s*\}\}(.*?)\{\{\s*end\s*\}\}/m) do |match|
        range_expr = $1.strip
        loop_content = $2

        collection = evaluate_expression(range_expr)

        case collection
        when Array
          if collection.empty?
            ""
          else
            collection.map_with_index do |item, index|
              # Create loop context
              loop_context = create_loop_context(item, index, range_expr)
              process_with_loop_context(loop_content, loop_context)
            end.join("")
          end
        else
          ""
        end
      end

      # Handle alternative {{ for item in collection }} loops
      result = result.gsub(/\{\{\s*for\s+(\w+)\s+in\s+([^}]+)\s*\}\}(.*?)\{\{\s*endfor\s*\}\}/m) do |match|
        item_name = $1.strip
        collection_expr = $2.strip
        loop_content = $3

        collection = evaluate_expression(collection_expr)

        case collection
        when Array
          if collection.empty?
            ""
          else
            collection.map_with_index do |item, index|
              # Create loop context for named item
              loop_context = create_for_loop_context(item, index, item_name)
              process_with_loop_context(loop_content, loop_context)
            end.join("")
          end
        else
          ""
        end
      end

      result
    end

    private def process_variables(template : String) : String
      template.gsub(/\{\{\s*([^}]+)\s*\}\}/) do |match|
        expression = $1.strip

        # Skip control structures
        next match if expression.starts_with?("if ") || expression.starts_with?("range ") ||
                      expression == "endif" || expression == "end" || expression == "else"

        # Skip function calls (already processed)
        next match if expression.includes?("(") && expression.includes?(")")

        value = evaluate_expression(expression)
        format_value(value)
      end
    end

    private def parse_function_args(args_str : String) : Array(String)
      return [] of String if args_str.strip.empty?

      args = [] of String

      # Simple argument parsing - split by comma, handle quotes
      parts = args_str.split(",")

      parts.each do |part|
        arg = part.strip

        # Handle different argument types
        if arg.starts_with?('"') && arg.ends_with?('"')
          # String literal
          args << arg[1..-2]
        elsif arg == "true"
          args << "true"
        elsif arg == "false"
          args << "false"
        elsif int_val = arg.to_i?
          args << int_val.to_s
        else
          # Variable reference
          value = evaluate_expression(arg)
          # Convert complex types to simple types for function arguments
          case value
          when String
            args << value
          when Int32, Bool, Time, Nil
            args << value.to_s
          when Content
            args << value.title
          when Page
            args << value.title
          when Site
            args << value.title
          when MenuItem
            args << value.name
          when Array(Content)
            args << value.map(&.title).join(",")
          when Array(MenuItem)
            args << value.map(&.name).join(",")
          when Hash(String, Array(MenuItem))
            # Convert menu hash to array of menu names
            menu_names = [] of String
            value.each do |menu_name, items|
              menu_names << "#{menu_name}: #{items.map(&.name).join(", ")}"
            end
            args << menu_names.join(",")
          when Hash(String, String)
            # Convert string hash to array of key-value pairs
            pairs = [] of String
            value.each do |key, val|
              pairs << "#{key}: #{val}"
            end
            args << pairs.join(",")
          when Hash(String, YAML::Any)
            # Convert YAML hash to array of key-value pairs
            pairs = [] of String
            value.each do |key, val|
              pairs << "#{key}: #{val}"
            end
            args << pairs.join(",")
          else
            args << value.to_s
          end
        end
      end

      args
    end

    private def evaluate_condition(condition : String) : Bool
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

    private def evaluate_expression(expression : String)
      # Handle dot notation (object.method)
      if expression.includes?(".")
        parts = expression.split(".")
        base = get_base_value(parts[0])

        parts[1..].each do |method|
          base = call_method(base, method)
        end

        base
      else
        get_base_value(expression)
      end
    end

    private def get_base_value(name : String)
      case name
      # Global objects
      when "site" then @site
      when "page" then @page
      when "now"  then Time.utc
        # Site shortcuts
      when "title"   then @site.title
      when "baseURL" then @site.base_url
        # Page shortcuts
      when "content"   then @page.try(&.content_html) || ""
      when "summary"   then @page.try(&.summary) || ""
      when "url"       then @page.try(&.url) || ""
      when "permalink" then @page.try(&.permalink) || ""
        # Context data
      when "params" then @page.try(&.params) || {} of String => YAML::Any
      when "data"   then @site.data
        # Navigation data
      when "site_menu" then @context.site_menu("main")
      else
        # Try as function call without parentheses
        if Functions.has_function?(name)
          Functions.call(name, [] of String)
        else
          nil
        end
      end
    end

    private def call_method(object, method : String)
      case {object, method}
      # Site methods
      when {Site, "Title"}              then object.as(Site).title
      when {Site, "BaseURL"}            then object.as(Site).base_url
      when {Site, "Pages"}              then object.as(Site).all_pages
      when {Site, "RegularPages"}       then object.as(Site).regular_pages
      when {Site, "Params"}             then object.as(Site).params
      when {Site, "Data"}               then object.as(Site).data
      when {Site, "Menus"}              then object.as(Site).menus
      when {Site, "Author"}             then object.as(Site).author
      when {Site, "Copyright"}          then object.as(Site).copyright
      when {Site, "Hugo"}               then object.as(Site).generator_info
      when {Site, "title"}              then object.as(Site).title
      when {Site, "base_url"}           then object.as(Site).base_url
      when {Site, "theme"}              then object.as(Site).theme
      when {Site, "theme_dir"}          then object.as(Site).theme_dir
      when {Site, "layouts_dir"}        then object.as(Site).layouts_dir
      when {Site, "static_dir"}         then object.as(Site).static_dir
      when {Site, "output_dir"}         then object.as(Site).output_dir
      when {Site, "content_dir"}        then object.as(Site).content_dir
      when {Site, "debug"}              then object.as(Site).debug
      when {Site, "build_config"}       then object.as(Site).build_config
      when {Site, "live_reload_config"} then object.as(Site).live_reload_config
      when {Site, "bundling_config"}    then object.as(Site).bundling_config
        # BuildConfig methods
      when {BuildConfig, "enabled"}     then object.as(BuildConfig).incremental
      when {BuildConfig, "incremental"} then object.as(BuildConfig).incremental
      when {BuildConfig, "parallel"}    then object.as(BuildConfig).parallel
      when {BuildConfig, "cache_dir"}   then object.as(BuildConfig).cache_dir
      when {BuildConfig, "max_workers"} then object.as(BuildConfig).max_workers
        # LiveReloadConfig methods
      when {LiveReloadConfig, "enabled"}        then object.as(LiveReloadConfig).enabled
      when {LiveReloadConfig, "websocket_path"} then object.as(LiveReloadConfig).websocket_path
      when {LiveReloadConfig, "debounce_ms"}    then object.as(LiveReloadConfig).debounce_ms
        # BundlingConfig methods
      when {BundlingConfig, "enabled"}     then object.as(BundlingConfig).enabled
      when {BundlingConfig, "minify"}      then object.as(BundlingConfig).minify
      when {BundlingConfig, "source_maps"} then object.as(BundlingConfig).source_maps
      when {BundlingConfig, "autoprefix"}  then object.as(BundlingConfig).autoprefix
        # Page methods
      when {Page, "Title"}       then object.as(Page).title
      when {Page, "Content"}     then object.as(Page).content_html
      when {Page, "Summary"}     then object.as(Page).summary
      when {Page, "URL"}         then object.as(Page).url
      when {Page, "Permalink"}   then object.as(Page).permalink
      when {Page, "Date"}        then object.as(Page).date
      when {Page, "Tags"}        then object.as(Page).tags
      when {Page, "Categories"}  then object.as(Page).categories
      when {Page, "WordCount"}   then object.as(Page).word_count
      when {Page, "ReadingTime"} then object.as(Page).reading_time
      when {Page, "Next"}        then object.as(Page).next
      when {Page, "Prev"}        then object.as(Page).prev
      when {Page, "Parent"}      then object.as(Page).parent
      when {Page, "Children"}    then object.as(Page).children
      when {Page, "Related"}     then object.as(Page).related
      when {Page, "Section"}     then object.as(Page).section
      when {Page, "Kind"}        then object.as(Page).kind
      when {Page, "Type"}        then object.as(Page).type
      when {Page, "Layout"}      then object.as(Page).layout
      when {Page, "Params"}      then object.as(Page).params
        # Page methods (lowercase)
      when {Page, "title"}      then object.as(Page).title
      when {Page, "content"}    then object.as(Page).content_html
      when {Page, "summary"}    then object.as(Page).summary
      when {Page, "url"}        then object.as(Page).url
      when {Page, "permalink"}  then object.as(Page).permalink
      when {Page, "date"}       then object.as(Page).date
      when {Page, "tags"}       then object.as(Page).tags
      when {Page, "categories"} then object.as(Page).categories
      when {Page, "kind"}       then object.as(Page).kind
      when {Page, "layout"}     then object.as(Page).layout
      when {Page, "file_path"}  then object.as(Page).file_path
        # Content methods (for arrays of Content)
      when {Content, "Title"}   then object.as(Content).title
      when {Content, "URL"}     then object.as(Content).url
      when {Content, "Date"}    then object.as(Content).date
      when {Content, "Summary"} then PageOperations.new(object.as(Content), @site.pages).summary
        # Time methods
      when {Time, "Year"}   then object.as(Time).year
      when {Time, "Month"}  then object.as(Time).month
      when {Time, "Day"}    then object.as(Time).day
      when {Time, "Format"} then object.as(Time).to_s("%Y-%m-%d")
        # Array methods
      when {Array, "len"}   then object.as(Array).size
      when {Array, "first"} then object.as(Array).first?
      when {Array, "last"}  then object.as(Array).last?
        # MenuItem methods
      when {MenuItem, "name"}     then object.as(MenuItem).name
      when {MenuItem, "url"}      then object.as(MenuItem).url
      when {MenuItem, "weight"}   then object.as(MenuItem).weight
      when {MenuItem, "external"} then object.as(MenuItem).external
      else
        nil
      end
    end

    private def create_loop_context(item, index : Int32, range_expr : String) : Hash(String, String | Int32)
      context = {} of String => String | Int32

      # Set loop variables
      context["."] = convert_to_string(item)
      context["$index"] = index

      # Handle assignment syntax: range $item := collection
      if range_expr.includes?(":=")
        var_name = range_expr.split(":=")[0].strip.lstrip("$")
        context[var_name] = convert_to_string(item)
      end

      context
    end

    private def create_for_loop_context(item, index : Int32, item_name : String) : Hash(String, String | Int32)
      context = {} of String => String | Int32

      # Set loop variables
      context["."] = convert_to_string(item)
      context["$index"] = index
      context[item_name] = convert_to_string(item)

      context
    end

    private def process_with_loop_context(template : String, loop_context : Hash(String, String | Int32)) : String
      result = template

      # Replace loop variables
      loop_context.each do |key, value|
        case key
        when "."
          # Current item context
          result = result.gsub("{{ . }}", format_value(value))
        when "$index"
          result = result.gsub("{{ $index }}", value.to_s)
        else
          # Named variables
          result = result.gsub("{{ $#{key} }}", format_value(value))
          result = result.gsub("{{ #{key} }}", format_value(value))
        end
      end

      # Process any remaining template syntax
      process(result)
    end

    private def format_value(value) : String
      case value
      when String        then value
      when Int32, Int64  then value.to_s
      when Bool          then value.to_s
      when Time          then value.to_s("%Y-%m-%d")
      when Array(String) then value.join(", ")
      when Array         then value.size.to_s # For other arrays, show count
      when Nil           then ""
      else                    value.to_s
      end
    end

    # Clean up any remaining unprocessed template syntax
    private def cleanup_remaining_syntax(template : String) : String
      result = template

      # Remove any remaining unmatched template blocks (be more aggressive)
      result = result.gsub(/\{\{\s*endfor\s*\}\}/, "")
      result = result.gsub(/\{\{\s*endif\s*\}\}/, "")
      result = result.gsub(/\{\{\s*else\s*\}\}/, "")
      result = result.gsub(/\{\{\s*end\s*\}\}/, "")

      # Remove any remaining template fragments or malformed syntax
      result = result.gsub(/\{\{\s*for\s+\w+\s+in\s+[^}]*\}\}/, "")
      result = result.gsub(/\{\{\s*if\s+[^}]*\}\}/, "")

      # Final pass: remove any remaining {{ }} blocks that weren't processed
      result = result.gsub(/\{\{\s*[^}]*\s*\}\}/, "")

      # Clean up any resulting empty lines or malformed HTML
      result = result.gsub(/>\s*">\s*</, "><")
      result = result.gsub(/>\s*">\s*\n/, ">\n")
      result = result.gsub(/>\s*">/, ">")

      result
    end

    # Helper method to convert complex types to strings for context
    private def convert_to_string(value) : String
      case value
      when String
        value
      when Content
        value.title
      when Page
        value.title
      when Site
        value.title
      when MenuItem
        value.name
      when Array(Content)
        value.map(&.title).join(", ")
      when Array(MenuItem)
        value.map(&.name).join(", ")
      when Hash(String, Array(MenuItem))
        # Convert menu hash to string representation
        pairs = [] of String
        value.each do |menu_name, items|
          pairs << "#{menu_name}: #{items.map(&.name).join(", ")}"
        end
        pairs.join("; ")
      when Hash(String, String)
        # Convert string hash to string representation
        pairs = [] of String
        value.each do |key, val|
          pairs << "#{key}: #{val}"
        end
        pairs.join("; ")
      when Hash(String, YAML::Any)
        # Convert YAML hash to string representation
        pairs = [] of String
        value.each do |key, val|
          pairs << "#{key}: #{val}"
        end
        pairs.join("; ")
      else
        value.to_s
      end
    end
  end
end
