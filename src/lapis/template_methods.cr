module Lapis
  # Shared method sets for efficient template processing across all processors
  # This module centralizes method definitions to eliminate duplication and ensure consistency
  module TemplateMethods
    # Site object methods - used for site.* template expressions
    SITE_METHODS = Set{
      :Title, :BaseURL, :Pages, :RegularPages, :Params, :Data, :Menus, :Author,
      :Copyright, :Hugo, :title, :"base_url", :theme, :"theme_dir", :"layouts_dir",
      :"static_dir", :"output_dir", :"content_dir", :debug, :"build_config",
      :"live_reload_config", :"bundling_config", :Debug, :"debug_info",
    }

    # Page object methods - used for page.* template expressions
    PAGE_METHODS = Set{
      :Title, :Content, :Summary, :URL, :Permalink, :Date, :Tags, :Categories,
      :WordCount, :ReadingTime, :Next, :Prev, :Parent, :Children, :Related,
      :Section, :Kind, :Type, :Layout, :Params, :title, :content, :summary,
      :url, :permalink, :date, :tags, :categories, :kind, :layout, :"file_path",
      :debug, :Debug, :"debug_info",
    }

    # Content object methods - used for content.* template expressions
    CONTENT_METHODS = Set{
      :Title, :URL, :Date, :Summary, :title, :url, :"date_formatted", :tags,
      :summary, :"reading_time",
    }

    # Array object methods - used for array.* template expressions
    ARRAY_METHODS = Set{
      "first", "last", "size", "empty?", "uniq", "uniq_by", "sample", "shuffle",
      "rotate", "reverse", "sort_by_length", "partition", "compact", "chunk",
      "index", "rindex", "array_truncate", "any?", "all?", "none?", "one?",
    }

    # Specialized navigation and UI component methods
    SECTION_NAV_METHODS = Set{:"has_prev?", :"has_next?", :prev, :next}
    BREADCRUMB_METHODS  = Set{:title, :url, :active}
    MENU_ITEM_METHODS   = Set{:name, :url, :external}

    # Time object methods - used for date/time template expressions
    TIME_METHODS = Set{:Year, :Month, :Day, :Format}

    # Configuration object methods
    MENUITEM_METHODS           = Set{:name, :url, :weight, :external}
    BUILD_CONFIG_METHODS       = Set{:enabled, :incremental, :parallel, :"cache_dir", :"max_workers"}
    LIVE_RELOAD_CONFIG_METHODS = Set{:enabled, :"websocket_path", :"debounce_ms"}
    BUNDLING_CONFIG_METHODS    = Set{:enabled, :minify, :"source_maps", :autoprefix}

    # String method symbols for symbol-based dispatch optimization
    STRING_METHOD_SYMBOLS = Set{
      :title, :content, :summary, :url, :permalink, :date, :tags, :categories,
      :author, :description, :"base_url", :theme, :"theme_dir", :"layouts_dir",
      :"static_dir", :"output_dir", :"content_dir", :debug, :"build_config",
      :"live_reload_config", :"bundling_config", :enabled, :incremental, :parallel,
      :"cache_dir", :"max_workers", :"websocket_path", :"debounce_ms", :minify,
      :"source_maps", :autoprefix, :Year, :Month, :Day, :Format, :len, :first,
      :last, :name, :weight, :external, :"has_prev?", :"has_next?", :prev, :next,
    }

    # Method name conversion helpers
    def self.string_to_symbol(method_name : String) : Symbol?
      case method_name
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
      when "theme"              then :theme
      when "theme_dir"          then :"theme_dir"
      when "layouts_dir"        then :"layouts_dir"
      when "static_dir"         then :"static_dir"
      when "output_dir"         then :"output_dir"
      when "content_dir"        then :"content_dir"
      when "debug"              then :debug
      when "debug_info"         then :"debug_info"
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
      when "has_prev?"          then :"has_prev?"
      when "has_next?"          then :"has_next?"
      when "prev"               then :prev
      when "next"               then :next
      else                           nil
      end
    end

    # Check if a method is valid for a given object type
    def self.valid_site_method?(method : String | Symbol) : Bool
      method_symbol = method.is_a?(String) ? string_to_symbol(method) : method
      method_symbol && SITE_METHODS.includes?(method_symbol)
    end

    def self.valid_page_method?(method : String | Symbol) : Bool
      method_symbol = method.is_a?(String) ? string_to_symbol(method) : method
      method_symbol && PAGE_METHODS.includes?(method_symbol)
    end

    def self.valid_content_method?(method : String | Symbol) : Bool
      method_symbol = method.is_a?(String) ? string_to_symbol(method) : method
      method_symbol && CONTENT_METHODS.includes?(method_symbol)
    end

    def self.valid_array_method?(method : String) : Bool
      ARRAY_METHODS.includes?(method)
    end

    def self.valid_time_method?(method : String | Symbol) : Bool
      method_symbol = method.is_a?(String) ? string_to_symbol(method) : method
      method_symbol && TIME_METHODS.includes?(method_symbol)
    end
  end
end
