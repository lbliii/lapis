require "./content"
require "./page_operations"

module Lapis
  struct BreadcrumbItem
    getter title : String
    getter url : String
    getter active : Bool

    def initialize(@title : String, @url : String, @active : Bool = false)
    end
  end

  class NavigationBuilder
    getter site_content : Array(Content)
    getter site_config : Hash(String, YAML::Any)

    def initialize(@site_content : Array(Content), @site_config : Hash(String, YAML::Any) = {} of String => YAML::Any)
    end

    def breadcrumbs(current_content : Content) : Array(BreadcrumbItem)
      breadcrumbs = [] of BreadcrumbItem

      # Add home
      breadcrumbs << BreadcrumbItem.new(
        title: site_title,
        url: "/",
        active: current_content.kind.home?
      )

      # Add section ancestors
      path_parts = current_content.section.split("/").reject(&.empty?)

      path_parts.each_with_index do |part, index|
        ancestor_path = path_parts[0..index].join("/")
        ancestor_url = "/#{ancestor_path}/"

        # Try to find section page for title
        section_content = find_section_content(ancestor_path)
        title = section_content ? section_content.title : humanize_path(part)

        breadcrumbs << BreadcrumbItem.new(
          title: title,
          url: ancestor_url,
          active: false
        )
      end

      # Add current page (if it's not home or a section index)
      if !current_content.kind.home? && !current_content.kind.section?
        breadcrumbs << BreadcrumbItem.new(
          title: current_content.title,
          url: current_content.url,
          active: true
        )
      else
        # Mark the last breadcrumb as active if this is a section page
        if last_crumb = breadcrumbs.last?
          breadcrumbs.pop
          breadcrumbs << BreadcrumbItem.new(
            title: last_crumb.title,
            url: last_crumb.url,
            active: true
          )
        end
      end

      breadcrumbs
    end

    # Enhanced NamedTuple-based safe navigation access
    def site_menu(menu_name : String = "main") : Array(MenuItem)
      # Use Hash.dig? for safe nested access (Hash already has dig? method)
      menu_config = @site_config.dig?("menus", menu_name)
      return [] of MenuItem unless menu_config

      case menu_config
      when Array
        menu_config.compact_map { |item| build_menu_item(item) }
      else
        [] of MenuItem
      end
    end

    def section_navigation(current_content : Content) : SectionNavigation
      return SectionNavigation.new unless current_content.kind.single?

      section_pages = @site_content.select { |c|
        c.section == current_content.section && c.kind.single?
      }.sort_by { |c| c.date || Time.unix(0) }.reverse

      current_index = section_pages.index(current_content)

      prev_page = current_index && current_index > 0 ? section_pages[current_index - 1] : nil
      next_page = current_index ? section_pages[current_index + 1]? : nil

      SectionNavigation.new(prev_page, next_page)
    end

    private def find_section_content(section_path : String) : Content?
      section_index_path = File.join(section_path, "_index")
      @site_content.find(&.url.starts_with?("/#{section_index_path}"))
    end

    private def humanize_path(path : String) : String
      path.split(/[-_]/).map(&.capitalize).join(" ")
    end

    private def site_title : String
      @site_config["title"]?.try(&.as_s) || "Home"
    end

    private def build_menu_item(item_config) : MenuItem?
      case item_config
      when Hash
        name = item_config["name"]?.try(&.as_s)
        url = item_config["url"]?.try(&.as_s)
        weight = item_config["weight"]?.try(&.as_i) || 0

        return nil unless name && url

        MenuItem.new(
          name: name,
          url: url,
          weight: weight,
          external: url.starts_with?("http")
        )
      else
        nil
      end
    end
  end

  struct MenuItem
    getter name : String
    getter url : String
    getter weight : Int32
    getter external : Bool

    def initialize(@name : String, @url : String, @weight : Int32 = 0, @external : Bool = false)
    end
  end

  struct SectionNavigation
    getter prev : Content?
    getter next : Content?

    def initialize(@prev : Content? = nil, @next : Content? = nil)
    end

    def has_prev? : Bool
      !@prev.nil?
    end

    def has_next? : Bool
      !@next.nil?
    end
  end
end
