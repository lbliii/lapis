require "./functions"
require "./site"
require "./page"
require "./navigation"
require "./base_processor"
require "./logger"
require "./exceptions"

module Lapis
  # Enhanced template processor with advanced functions
  class FunctionProcessor < BaseProcessor
    getter context : TemplateContext
    getter site : Site
    getter page : Page?

    # Cache compiled regex patterns to avoid recompilation
    # This prevents stack overflow from excessive Regex object creation
    class_property cleanup_regexes : Hash(String, Regex) = {
      "endfor" => /\{\{\s*endfor\s*\}\}/,
      "endif" => /\{\{\s*endif\s*\}\}/,
      "else" => /\{\{\s*else\s*\}\}/,
      "end" => /\{\{\s*end\s*\}\}/,
      "for_block" => /\{\{\s*for\s+\w+\s+in\s+[^}]*\}\}/,
      "if_block" => /\{\{\s*if\s+[^}]*\}\}/,
      "any_block" => /\{\{\s*[^}]*\s*\}\}/,
      "empty_quote_bracket" => />\s*">\s*</,
      "empty_quote_newline" => />\s*">\s*\n/,
      "empty_quote" => />\s*">/,
    }

    # Accept Site object instead of creating a new one
    # This prevents O(n²) memory explosion from duplicate Site objects
    def initialize(@context : TemplateContext, @site : Site)
      super(@context)
      
      if @context.content.is_a?(Content)
        @page = Page.new(@context.content.as(Content), @site)
      end

      # Initialize global functions
      Functions.setup
    end
    
    # Backward compatibility: allow creating without Site (will create one)
    def self.new(context : TemplateContext)
      site = Site.new(context.config, context.query.site_content)
      new(context, site)
    end

    # Optimized tuple-based method dispatch
    private def dispatch_method_tuple(object, method_symbol : Symbol)
      # Use tuple operations for efficient method dispatch
      case {object.class, method_symbol}
      when {Site.class, _}
        dispatch_site_method(object, method_symbol) if TemplateMethods::SITE_METHODS.includes?(method_symbol)
      when {Page.class, _}
        dispatch_page_method(object, method_symbol) if TemplateMethods::PAGE_METHODS.includes?(method_symbol)
      when {Content.class, _}
        dispatch_content_method(object, method_symbol) if TemplateMethods::CONTENT_METHODS.includes?(method_symbol)
      when {Time.class, _}
        dispatch_time_method(object, method_symbol) if TemplateMethods::TIME_METHODS.includes?(method_symbol)
      when {Array.class, _}
        dispatch_array_method(object, method_symbol) if TemplateMethods::ARRAY_METHODS.includes?(method_symbol.to_s)
      when {MenuItem.class, _}
        dispatch_menuitem_method(object, method_symbol) if TemplateMethods::MENUITEM_METHODS.includes?(method_symbol)
      when {BuildConfig.class, _}
        dispatch_build_config_method(object, method_symbol) if TemplateMethods::BUILD_CONFIG_METHODS.includes?(method_symbol)
      when {LiveReloadConfig.class, _}
        dispatch_live_reload_config_method(object, method_symbol) if TemplateMethods::LIVE_RELOAD_CONFIG_METHODS.includes?(method_symbol)
      when {BundlingConfig.class, _}
        dispatch_bundling_config_method(object, method_symbol) if TemplateMethods::BUNDLING_CONFIG_METHODS.includes?(method_symbol)
      else
        nil
      end
    end

    # Tuple-based method dispatchers using tuple iteration
    protected def dispatch_site_method(object, method : Symbol)
      # Use tuple to_a for iteration and mapping
      site_methods_tuple = TemplateMethods::SITE_METHODS.to_a
      site_methods_tuple.each do |method_item|
        return handle_site_method(object, method_item) if method_item == method
      end
      nil
    end

    protected def dispatch_page_method(object, method : Symbol) : String?
      TemplateMethods::PAGE_METHODS.to_a.each do |method_item|
        return handle_page_method(object, method_item) if method_item == method
      end
      nil
    end

    protected def dispatch_content_method(object, method : Symbol) : String?
      TemplateMethods::CONTENT_METHODS.to_a.each do |method_item|
        return handle_content_method(object, method_item) if method_item == method
      end
      nil
    end

    protected def dispatch_time_method(object, method : Symbol) : String?
      TemplateMethods::TIME_METHODS.to_a.each do |method_item|
        return handle_time_method(object, method_item) if method_item == method
      end
      nil
    end

    # Override base class method for Symbol parameters
    protected def dispatch_array_method(object, method : Symbol) : String?
      TemplateMethods::ARRAY_METHODS.each do |method_item|
        if method_item == method.to_s
          return handle_array_method_string(object, method_item)
        end
      end
      nil
    end

    private def dispatch_menuitem_method(object, method_symbol : Symbol) : String?
      TemplateMethods::MENUITEM_METHODS.to_a.each do |method|
        return handle_menuitem_method(object, method) if method == method_symbol
      end
      nil
    end

    private def dispatch_build_config_method(object, method_symbol : Symbol)
      TemplateMethods::BUILD_CONFIG_METHODS.to_a.each do |method|
        return handle_build_config_method(object, method) if method == method_symbol
      end
      nil
    end

    private def dispatch_live_reload_config_method(object, method_symbol : Symbol)
      TemplateMethods::LIVE_RELOAD_CONFIG_METHODS.to_a.each do |method|
        return handle_live_reload_config_method(object, method) if method == method_symbol
      end
      nil
    end

    private def dispatch_bundling_config_method(object, method_symbol : Symbol)
      TemplateMethods::BUNDLING_CONFIG_METHODS.to_a.each do |method|
        return handle_bundling_config_method(object, method) if method == method_symbol
      end
      nil
    end

    # Handler methods using tuple operations for efficient processing
    private def handle_site_method(object, method : Symbol)
      case method
      when :Title                then object.is_a?(Site) ? object.as(Site).title : nil
      when :title                then object.is_a?(Site) ? object.as(Site).title : nil
      when :BaseURL              then object.is_a?(Site) ? object.as(Site).base_url : nil
      when :"base_url"           then object.is_a?(Site) ? object.as(Site).base_url : nil
      when :Pages                then object.is_a?(Site) ? object.as(Site).all_pages : nil
      when :RegularPages         then object.is_a?(Site) ? object.as(Site).regular_pages : nil
      when :Params               then object.is_a?(Site) ? object.as(Site).params.to_s : nil
      when :Data                 then object.is_a?(Site) ? object.as(Site).data.to_s : nil
      when :Menus                then object.is_a?(Site) ? object.as(Site).menus.to_s : nil
      when :Author               then object.is_a?(Site) ? object.as(Site).author : nil
      when :Copyright            then object.is_a?(Site) ? object.as(Site).copyright : nil
      when :Hugo                 then object.is_a?(Site) ? object.as(Site).generator_info : nil
      when :theme                then object.is_a?(Site) ? object.as(Site).theme : nil
      when :"theme_dir"          then object.is_a?(Site) ? object.as(Site).theme_dir : nil
      when :"layouts_dir"        then object.is_a?(Site) ? object.as(Site).layouts_dir : nil
      when :"static_dir"         then object.is_a?(Site) ? object.as(Site).static_dir : nil
      when :"output_dir"         then object.is_a?(Site) ? object.as(Site).output_dir : nil
      when :"content_dir"        then object.is_a?(Site) ? object.as(Site).content_dir : nil
      when :debug, :Debug        then object.is_a?(Site) ? object.as(Site).debug.to_s : nil
      when :"debug_info"         then object.is_a?(Site) ? object.as(Site).debug_info : nil
      when :"build_config"       then object.is_a?(Site) ? object.as(Site).build_config : nil
      when :"live_reload_config" then object.is_a?(Site) ? object.as(Site).live_reload_config : nil
      when :"bundling_config"    then object.is_a?(Site) ? object.as(Site).bundling_config : nil
      else                            nil
      end
    end

    private def handle_page_method(object, method : Symbol) : String?
      case method
      when :Title, :title           then object.is_a?(Page) ? object.as(Page).title : nil
      when :Content, :content       then object.is_a?(Page) ? object.as(Page).content_html : nil
      when :Summary, :summary       then object.is_a?(Page) ? object.as(Page).summary : nil
      when :URL, :url               then object.is_a?(Page) ? object.as(Page).url : nil
      when :Permalink, :permalink   then object.is_a?(Page) ? object.as(Page).permalink : nil
      when :Date, :date             then object.is_a?(Page) ? object.as(Page).date.to_s : nil
      when :Tags, :tags             then object.is_a?(Page) ? object.as(Page).tags.to_s : nil
      when :Categories, :categories then object.is_a?(Page) ? object.as(Page).categories.to_s : nil
      when :WordCount               then object.is_a?(Page) ? object.as(Page).word_count.to_s : nil
      when :ReadingTime             then object.is_a?(Page) ? object.as(Page).reading_time.to_s : nil
      when :Next                    then object.is_a?(Page) ? object.as(Page).next.to_s : nil
      when :Prev                    then object.is_a?(Page) ? object.as(Page).prev.to_s : nil
      when :Parent                  then object.is_a?(Page) ? object.as(Page).parent.to_s : nil
      when :Children                then object.is_a?(Page) ? object.as(Page).children.to_s : nil
      when :Related                 then object.is_a?(Page) ? object.as(Page).related.to_s : nil
      when :Section                 then object.is_a?(Page) ? object.as(Page).section.to_s : nil
      when :Kind, :kind             then object.is_a?(Page) ? object.as(Page).kind.to_s : nil
      when :Type                    then object.is_a?(Page) ? object.as(Page).type.to_s : nil
      when :Layout, :layout         then object.is_a?(Page) ? object.as(Page).layout.to_s : nil
      when :Params                  then object.is_a?(Page) ? object.as(Page).params.to_s : nil
      when :"file_path"             then object.is_a?(Page) ? object.as(Page).file_path : nil
      when :debug, :Debug           then object.is_a?(Page) ? object.as(Page).debug.to_s : nil
      when :"debug_info"            then object.is_a?(Page) ? object.as(Page).debug_info : nil
      else                               nil
      end
    end

    private def handle_content_method(object, method : Symbol) : String?
      case method
      when :Title then object.is_a?(Content) ? object.as(Content).title : nil
      when :URL   then object.is_a?(Content) ? object.as(Content).url : nil
      when :Date  then object.is_a?(Content) ? object.as(Content).date.to_s : nil
      when :Summary
        if object.is_a?(Content)
          content = object.as(Content)
          PageOperations.new(content, @site.pages).summary
        else
          nil
        end
      else nil
      end
    end

    private def handle_time_method(object, method : Symbol) : String?
      case method
      when :Year   then object.is_a?(Time) ? object.as(Time).year.to_s : nil
      when :Month  then object.is_a?(Time) ? object.as(Time).month.to_s : nil
      when :Day    then object.is_a?(Time) ? object.as(Time).day.to_s : nil
      when :Format then object.is_a?(Time) ? object.as(Time).to_s("%Y-%m-%d") : nil
      else              nil
      end
    end

    private def handle_array_method_string(object, method : String) : String?
      return nil unless object.is_a?(Array)
      array = object.as(Array)

      case method
      when "len"     then array.size.to_s
      when "first"   then array.first?.to_s
      when "last"    then array.last?.to_s
      when "uniq"    then array.uniq.to_s
      when "sample"  then array.sample.to_s
      when "shuffle" then array.shuffle.to_s
      when "reverse" then array.reverse.to_s
      when "compact" then array.compact.to_s
      when "empty?"  then array.empty?.to_s
      when "any?"    then array.any? { |item| !item.nil? }.to_s
      when "all?"    then array.all? { |item| !item.nil? }.to_s
      when "none?"   then array.none?(Nil).to_s
      when "one?"    then array.one? { |item| !item.nil? }.to_s
      when "size"    then array.size.to_s
      else                nil
      end
    end

    private def handle_menuitem_method(object, method : Symbol) : String?
      case method
      when :name     then object.is_a?(MenuItem) ? object.as(MenuItem).name : nil
      when :url      then object.is_a?(MenuItem) ? object.as(MenuItem).url : nil
      when :weight   then object.is_a?(MenuItem) ? object.as(MenuItem).weight.to_s : nil
      when :external then object.is_a?(MenuItem) ? object.as(MenuItem).external.to_s : nil
      else                nil
      end
    end

    private def handle_build_config_method(object, method : Symbol)
      case method
      when :enabled       then object.is_a?(BuildConfig) ? object.as(BuildConfig).incremental? : nil
      when :incremental   then object.is_a?(BuildConfig) ? object.as(BuildConfig).incremental? : nil
      when :parallel      then object.is_a?(BuildConfig) ? object.as(BuildConfig).parallel? : nil
      when :"cache_dir"   then object.is_a?(BuildConfig) ? object.as(BuildConfig).cache_dir : nil
      when :"max_workers" then object.is_a?(BuildConfig) ? object.as(BuildConfig).max_workers : nil
      else                     nil
      end
    end

    private def handle_live_reload_config_method(object, method : Symbol)
      case method
      when :enabled          then object.is_a?(LiveReloadConfig) ? object.as(LiveReloadConfig).enabled : nil
      when :"websocket_path" then object.is_a?(LiveReloadConfig) ? object.as(LiveReloadConfig).websocket_path : nil
      when :"debounce_ms"    then object.is_a?(LiveReloadConfig) ? object.as(LiveReloadConfig).debounce_ms : nil
      else                        nil
      end
    end

    private def handle_bundling_config_method(object, method : Symbol)
      case method
      when :enabled       then object.is_a?(BundlingConfig) ? object.as(BundlingConfig).enabled? : nil
      when :minify        then object.is_a?(BundlingConfig) ? object.as(BundlingConfig).minify? : nil
      when :"source_maps" then object.is_a?(BundlingConfig) ? object.as(BundlingConfig).source_maps? : nil
      when :autoprefix    then object.is_a?(BundlingConfig) ? object.as(BundlingConfig).autoprefix? : nil
      else                     nil
      end
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
      template.gsub(TemplatePatterns::FUNCTION_CALL_PATTERN) do |match|
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

        result = result.gsub(TemplatePatterns::IF_CONDITIONAL_PATTERN) do |match|
          condition = $1.strip
          content = $2

          # Check if there's an else clause
          if content.includes?("{{ else }}")
            # Find the correct else - account for nested if/endif blocks
            else_pos = find_matching_else(content)
            if else_pos
              range = 0...else_pos
              if_content = content[range]
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
      # Use more efficient regex patterns to avoid backtracking
      else_pattern = /\{\{\s*else\s*\}\}/
      if_pattern = /\{\{\s*if\s+[^}]+\s*\}\}/
      endif_pattern = /\{\{\s*endif\s*\}\}/

      pos = 0
      nesting_level = 0
      max_iterations = content.size / 10 # Prevent infinite loops
      iteration_count = 0

      while pos < content.size && iteration_count < max_iterations
        iteration_count += 1

        # Find the next occurrence of if, else, or endif with bounds checking
        if_match = content.match(if_pattern, pos, options: Regex::MatchOptions::None)
        else_match = content.match(else_pattern, pos, options: Regex::MatchOptions::None)
        endif_match = content.match(endif_pattern, pos, options: Regex::MatchOptions::None)

        # Find which comes first
        next_if = if_match ? if_match.begin(0) : Int32::MAX
        next_else = else_match ? else_match.begin(0) : Int32::MAX
        next_endif = endif_match ? endif_match.begin(0) : Int32::MAX

        if next_if < next_else && next_if < next_endif
          # Found nested if
          nesting_level += 1
          pos = next_if + (if_match.try(&.[0].size) || 0)
        elsif next_endif < next_else
          # Found endif
          if nesting_level == 0
            break # This endif closes our block, no else found
          else
            nesting_level -= 1
            pos = next_endif + (endif_match.try(&.[0].size) || 0)
          end
        else
          # Found else
          if nesting_level == 0
            return next_else # This is our matching else
          else
            pos = next_else + (else_match.try(&.[0].size) || 0)
          end
        end
      end

      nil
    end

    private def process_loops(template : String) : String
      # Handle {{ range collection }} loops
      result = template.gsub(TemplatePatterns::RANGE_LOOP_PATTERN) do |match|
        range_expr = $1.strip
        loop_content = $2

        collection = evaluate_expression(range_expr)

        case collection
        when Array(Content)
          if collection.empty?
            ""
          else
            collection.map_with_index do |item, index|
              # Create loop context for Content objects
              loop_context = create_loop_context(item, index, range_expr)
              process_with_loop_context(loop_content, loop_context)
            end.join("")
          end
        when Array(MenuItem)
          if collection.empty?
            ""
          else
            collection.map_with_index do |item, index|
              # Create loop context for MenuItem objects
              loop_context = create_loop_context(item, index, range_expr)
              process_with_loop_context(loop_content, loop_context)
            end.join("")
          end
        when Array
          if collection.empty?
            ""
          else
            collection.map_with_index do |item, index|
              # Create loop context for generic arrays
              loop_context = create_loop_context(item, index, range_expr)
              process_with_loop_context(loop_content, loop_context)
            end.join("")
          end
        else
          ""
        end
      end

      # Handle alternative {{ for item in collection }} loops
      result = result.gsub(TemplatePatterns::FOR_LOOP_PATTERN) do |match|
        item_name = $1.strip
        collection_expr = $2.strip
        loop_content = $3

        collection = evaluate_expression(collection_expr)

        case collection
        when Array(Content)
          if collection.empty?
            ""
          else
            collection.map_with_index do |item, index|
              # Create loop context for Content objects
              loop_context = create_for_loop_context(item, index, item_name)
              process_with_loop_context(loop_content, loop_context)
            end.join("")
          end
        when Array(MenuItem)
          if collection.empty?
            ""
          else
            collection.map_with_index do |item, index|
              # Create loop context for MenuItem objects
              loop_context = create_for_loop_context(item, index, item_name)
              process_with_loop_context(loop_content, loop_context)
            end.join("")
          end
        when Array
          if collection.empty?
            ""
          else
            collection.map_with_index do |item, index|
              # Create loop context for generic arrays
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
      template.gsub(TemplatePatterns::VARIABLE_PATTERN) do |match|
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
      # Use optimized tuple-based method dispatch
      # Convert string to symbol for dispatch
      method_symbol = case method
                      when "Title"              then :Title
                      when "BaseURL"            then :BaseURL
                      when "Pages"              then :Pages
                      when "RegularPages"       then :RegularPages
                      when "Params"             then :Params
                      when "Data"               then :Data
                      when "Menus"              then :Menus
                      when "Author"             then :Author
                      when "Copyright"          then :Copyright
                      when "Hugo"               then :Hugo
                      when "title"              then :title
                      when "base_url"           then :"base_url"
                      when "pages"              then :Pages
                      when "regular_pages"      then :RegularPages
                      when "theme"              then :theme
                      when "theme_dir"          then :"theme_dir"
                      when "layouts_dir"        then :"layouts_dir"
                      when "static_dir"         then :"static_dir"
                      when "output_dir"         then :"output_dir"
                      when "content_dir"        then :"content_dir"
                      when "debug"              then :debug
                      when "build_config"       then :"build_config"
                      when "live_reload_config" then :"live_reload_config"
                      when "bundling_config"    then :"bundling_config"
                      when "enabled"            then :enabled
                      when "incremental"        then :incremental
                      when "parallel"           then :parallel
                      when "cache_dir"          then :"cache_dir"
                      when "max_workers"        then :"max_workers"
                      when "websocket_path"     then :"websocket_path"
                      when "debounce_ms"        then :"debounce_ms"
                      when "minify"             then :minify
                      when "source_maps"        then :"source_maps"
                      when "autoprefix"         then :autoprefix
                      when "Content"            then :Content
                      when "Summary"            then :Summary
                      when "URL"                then :URL
                      when "Permalink"          then :Permalink
                      when "Date"               then :Date
                      when "Tags"               then :Tags
                      when "Categories"         then :Categories
                      when "WordCount"          then :WordCount
                      when "ReadingTime"        then :ReadingTime
                      when "Next"               then :Next
                      when "Prev"               then :Prev
                      when "Parent"             then :Parent
                      when "Children"           then :Children
                      when "Related"            then :Related
                      when "Section"            then :Section
                      when "Kind"               then :Kind
                      when "Type"               then :Type
                      when "Layout"             then :Layout
                      when "content"            then :content
                      when "summary"            then :summary
                      when "url"                then :url
                      when "permalink"          then :permalink
                      when "date"               then :date
                      when "tags"               then :tags
                      when "categories"         then :categories
                      when "kind"               then :kind
                      when "layout"             then :layout
                      when "file_path"          then :"file_path"
                      when "Year"               then :Year
                      when "Month"              then :Month
                      when "Day"                then :Day
                      when "Format"             then :Format
                      when "len"                then :len
                      when "first"              then :first
                      when "last"               then :last
                      when "name"               then :name
                      when "weight"             then :weight
                      when "external"           then :external
                      else                           return nil
                      end
      dispatch_method_tuple(object, method_symbol)
    end

    # Legacy method dispatch (kept for reference)
    private def call_method_legacy(object, method : String)
      # Temporarily disabled due to SafeCast dependency
      return nil
    end

    private def create_loop_context(item, index : Int32, range_expr : String) : Hash(String, String | Int32 | Content | Page | Site | MenuItem)
      context = {} of String => String | Int32 | Content | Page | Site | MenuItem

      # Set loop variables - preserve objects for property access
      context["."] = item
      context["$index"] = index

      # Handle assignment syntax: range $item := collection
      if range_expr.includes?(":=")
        var_name = range_expr.split(":=")[0].strip.lstrip("$")
        context[var_name] = item
      end

      context
    end

    private def create_for_loop_context(item, index : Int32, item_name : String) : Hash(String, String | Int32 | Content | Page | Site | MenuItem)
      context = {} of String => String | Int32 | Content | Page | Site | MenuItem

      # Set loop variables - preserve objects for property access
      context["."] = item
      context["$index"] = index
      context[item_name] = item

      context
    end

    private def process_with_loop_context(template : String, loop_context : Hash(String, String | Int32 | Content | Page | Site | MenuItem)) : String
      result = template

      # First, handle dot notation property access for current item
      if current_item = loop_context["."]?
        # Replace patterns like {{ .property }}
        result = result.gsub(/\{\{\s*\.(\w+)\s*\}\}/) do |match|
          property = $1
          property_value = call_method(current_item, property)
          format_value(property_value)
        end
      end

      # Replace loop variables
      loop_context.each do |key, value|
        case key
        when "."
          # Current item context - store object for method access
          result = result.gsub("{{ . }}", format_value(value))
        when "$index"
          result = result.gsub("{{ $index }}", value.to_s)
        else
          # Named variables - handle both property access and direct access
          # Handle patterns like {{ item.property }}
          result = result.gsub(/\{\{\s*#{Regex.escape(key)}\.(\w+)\s*\}\}/) do |match|
            property = $1
            property_value = call_method(value, property)
            format_value(property_value)
          end

          # Handle direct variable access
          result = result.gsub("{{ $#{key} }}", format_value(value))
          result = result.gsub("{{ #{key} }}", format_value(value))
        end
      end

      # Process any remaining template syntax
      process(result)
    end

    # Override base class method with function-specific logic
    protected def format_value(value) : String
      case value
      when String          then cache_string(value)
      when Int32, Int64    then cache_string(value.to_s)
      when Bool            then cache_string(value.to_s)
      when Time            then cache_string(value.to_s("%Y-%m-%d"))
      when Array(String)   then cache_string(value.join(", "))
      when Array(Content)  then cache_string(value.map(&.title).join(", "))
      when Array(MenuItem) then cache_string(value.map(&.name).join(", "))
      when Array           then cache_string(value.size.to_s) # For other arrays, show count
      when Nil             then ""
      when Site            then cache_string(value.as(Site).title)
      when Page            then cache_string(value.as(Page).title)
      when Content         then cache_string(value.as(Content).title)
      when MenuItem        then cache_string(value.as(MenuItem).name)
      else                      cache_string(value.to_s)
      end
    end

    # Clean up any remaining unprocessed template syntax
    # Uses cached regex patterns to avoid excessive object creation
    private def cleanup_remaining_syntax(template : String) : String
      result = template
      regexes = self.class.cleanup_regexes

      # Remove any remaining unmatched template blocks (be more aggressive)
      result = result.gsub(regexes["endfor"], "")
      result = result.gsub(regexes["endif"], "")
      result = result.gsub(regexes["else"], "")
      result = result.gsub(regexes["end"], "")

      # Remove any remaining template fragments or malformed syntax
      result = result.gsub(regexes["for_block"], "")
      result = result.gsub(regexes["if_block"], "")

      # Final pass: remove any remaining {{ }} blocks that weren't processed
      result = result.gsub(regexes["any_block"], "")

      # Clean up any resulting empty lines or malformed HTML
      result = result.gsub(regexes["empty_quote_bracket"], "><")
      result = result.gsub(regexes["empty_quote_newline"], ">\n")
      result = result.gsub(regexes["empty_quote"], ">")

      result
    end

    # Helper method to convert complex types to strings for context
    private def convert_to_string(value) : String
      case value
      when String
        cache_string(value)
      when Content
        cache_string(value.title)
      when Page
        cache_string(value.title)
      when Site
        cache_string(value.title)
      when MenuItem
        cache_string(value.name)
      when Array(Content)
        cache_string(value.map(&.title).join(", "))
      when Array(MenuItem)
        cache_string(value.map(&.name).join(", "))
      when Hash(String, Array(MenuItem))
        # Convert menu hash to string representation
        pairs = [] of String
        value.each do |menu_name, items|
          pairs << "#{menu_name}: #{items.map(&.name).join(", ")}"
        end
        cache_string(pairs.join("; "))
      when Hash(String, String)
        # Convert string hash to string representation
        pairs = [] of String
        value.each do |key, val|
          pairs << "#{key}: #{val}"
        end
        cache_string(pairs.join("; "))
      when Hash(String, YAML::Any)
        # Convert YAML hash to string representation
        pairs = [] of String
        value.each do |key, val|
          pairs << "#{key}: #{val}"
        end
        cache_string(pairs.join("; "))
      else
        cache_string(value.to_s)
      end
    end
  end
end
