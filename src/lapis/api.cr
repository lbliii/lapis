require "json"
require "yaml"
require "./content"
require "./collections"
require "./site"
require "./generator"
require "./config"
require "./logger"
require "./exceptions"

module Lapis
  # REST API for Lapis content management and site information
  class API
    property config : Config
    property generator : Generator
    property site : Site
    property collections : ContentCollections

    def initialize(@config : Config, @generator : Generator)
      @site = Site.new(@config)
      @collections = ContentCollections.new([] of Content)
    end

    # Initialize with loaded content
    def self.with_content(config : Config, generator : Generator, content : Array(Content))
      api = new(config, generator)
      api.site = Site.new(config, content)
      api.collections = ContentCollections.new(content, {} of String => YAML::Any)
      api
    end

    # Main API handler - routes requests to appropriate endpoints
    def handle_request(context : HTTP::Server::Context) : Bool
      path = context.request.path
      method = context.request.method

      # API routes
      case {method, path}
      when {"GET", "/api"}
        api_info(context)
      when {"GET", "/api/site"}
        site_info(context)
      when {"GET", "/api/content"}
        list_content(context)
      when {"GET", /^\/api\/content\/(.+)$/}
        get_content(context, $1)
      when {"POST", "/api/content"}
        create_content(context)
      when {"PUT", /^\/api\/content\/(.+)$/}
        update_content(context, $1)
      when {"DELETE", /^\/api\/content\/(.+)$/}
        delete_content(context, $1)
      when {"GET", "/api/collections"}
        list_collections(context)
      when {"GET", /^\/api\/collections\/(.+)$/}
        get_collection(context, $1)
      when {"GET", "/api/posts"}
        list_posts(context)
      when {"GET", "/api/pages"}
        list_pages(context)
      when {"GET", "/api/tags"}
        list_tags(context)
      when {"GET", /^\/api\/tags\/(.+)$/}
        get_tag_content(context, $1)
      when {"GET", "/api/categories"}
        list_categories(context)
      when {"GET", /^\/api\/categories\/(.+)$/}
        get_category_content(context, $1)
      when {"GET", "/api/build"}
        build_info(context)
      when {"POST", "/api/build"}
        trigger_build(context)
      when {"GET", "/api/analytics"}
        analytics_info(context)
      when {"GET", "/api/functions"}
        list_functions(context)
      when {"GET", /^\/api\/functions\/(.+)$/}
        get_function_info(context, $1)
      when {"POST", /^\/api\/functions\/(.+)$/}
        execute_function(context, $1)
      when {"GET", "/api/health"}
        health_check(context)
      else
        false # Not an API route
      end
    end

    # API Information
    private def api_info(context : HTTP::Server::Context)
      endpoints = {
        "site"        => "/api/site",
        "content"     => "/api/content",
        "collections" => "/api/collections",
        "posts"       => "/api/posts",
        "pages"       => "/api/pages",
        "tags"        => "/api/tags",
        "categories"  => "/api/categories",
        "build"       => "/api/build",
        "analytics"   => "/api/analytics",
        "functions"   => "/api/functions",
        "health"      => "/api/health",
      }

      response = {
        "name"        => to_json_any("Lapis API"),
        "version"     => to_json_any(Lapis::VERSION),
        "description" => to_json_any("REST API for Lapis static site generator"),
        "endpoints"   => to_json_any(endpoints),
      }
      send_json(context, response)
    end

    # Site Information
    private def site_info(context : HTTP::Server::Context)
      response = {
        "title"           => @site.title,
        "description"     => @site.description,
        "base_url"        => @site.base_url,
        "author"          => @site.author,
        "language"        => @site.language_code,
        "theme"           => @site.theme,
        "copyright"       => @site.copyright,
        "content_count"   => @site.pages.size,
        "published_posts" => @site.pages.count(&.feedable?),
        "draft_posts"     => @site.pages.count(&.draft),
      }
      send_json(context, response)
    end

    # List all content
    private def list_content(context : HTTP::Server::Context)
      query_params = parse_query_params(context)
      limit = query_params["limit"]?.try(&.to_i?) || 50
      offset = query_params["offset"]?.try(&.to_i?) || 0
      include_drafts = query_params["include_drafts"]? == "true"

      content = @site.pages
      content = content.reject(&.draft) unless include_drafts
      content = content[offset, limit]

      response = {
        "content" => content.map { |c| content_to_hash(c) },
        "total"   => @site.pages.size,
        "limit"   => limit,
        "offset"  => offset,
      }
      send_json(context, response)
    end

    # Get specific content by URL or file path
    private def get_content(context : HTTP::Server::Context, identifier : String)
      content = @collections.find_by_url("/#{identifier}/") ||
                @collections.find_by_file_path(identifier) ||
                @site.pages.find { |c| c.url == "/#{identifier}/" }

      if content
        send_json(context, content_to_hash(content))
      else
        send_error(context, 404, "Content not found")
      end
    end

    # Create new content
    private def create_content(context : HTTP::Server::Context)
      body = context.request.body.try(&.gets_to_end) || ""
      data = JSON.parse(body).as_h

      title = data["title"]?.try(&.as_s) || "Untitled"
      type = data["type"]?.try(&.as_s) || "page"
      content_text = data["content"]?.try(&.as_s) || ""

      Content.create_new(type, title)

      # Find the created content
      created_content = @site.pages.find { |c| c.title == title }

      if created_content
        send_json(context, {
          "message" => "Content created successfully",
          "content" => content_to_hash(created_content),
        })
      else
        send_error(context, 500, "Failed to create content")
      end
    rescue ex
      send_error(context, 400, "Invalid request: #{ex.message}")
    end

    # Update existing content
    private def update_content(context : HTTP::Server::Context, identifier : String)
      content = @collections.find_by_url("/#{identifier}/") ||
                @collections.find_by_file_path(identifier)

      if content
        begin
          body = context.request.body.try(&.gets_to_end) || ""
          data = JSON.parse(body).as_h

          # Update content properties
          content.title = data["title"]?.try(&.as_s) || content.title
          content.description = data["description"]?.try(&.as_s) || content.description
          content.body = data["content"]?.try(&.as_s) || content.body

          # Save to file
          save_content_to_file(content)

          send_json(context, {
            "message" => "Content updated successfully",
            "content" => content_to_hash(content),
          })
        rescue ex
          send_error(context, 400, "Invalid request: #{ex.message}")
        end
      else
        send_error(context, 404, "Content not found")
      end
    end

    # Delete content
    private def delete_content(context : HTTP::Server::Context, identifier : String)
      content = @collections.find_by_url("/#{identifier}/") ||
                @collections.find_by_file_path(identifier)

      if content
        begin
          File.delete(content.file_path)
          send_json(context, {"message" => "Content deleted successfully"})
        rescue ex
          send_error(context, 500, "Failed to delete content: #{ex.message}")
        end
      else
        send_error(context, 404, "Content not found")
      end
    end

    # List collections
    private def list_collections(context : HTTP::Server::Context)
      response = {
        "collections" => @collections.collections.map do |name, collection|
          {
            "name"          => name,
            "content_count" => collection.content.size,
            "path"          => collection.output_path,
          }
        end,
      }
      send_json(context, response)
    end

    # Get specific collection
    private def get_collection(context : HTTP::Server::Context, name : String)
      collection = @collections.collections[name]?

      if collection
        response = {
          "name"          => name,
          "content"       => collection.content.map { |c| content_to_hash(c) },
          "content_count" => collection.content.size,
        }
        send_json(context, response)
      else
        send_error(context, 404, "Collection not found")
      end
    end

    # List posts
    private def list_posts(context : HTTP::Server::Context)
      query_params = parse_query_params(context)
      include_drafts = query_params["include_drafts"]? == "true"
      limit = query_params["limit"]?.try(&.to_i?) || 10

      posts = @site.pages.select(&.post?)
      posts = posts.reject(&.draft) unless include_drafts
      posts = posts.sort.first(limit)

      response = {
        "posts" => posts.map { |p| content_to_hash(p) },
        "total" => posts.size,
      }
      send_json(context, response)
    end

    # List pages
    private def list_pages(context : HTTP::Server::Context)
      pages = @site.pages.select(&.page?)

      response = {
        "pages" => pages.map { |p| content_to_hash(p) },
        "total" => pages.size,
      }
      send_json(context, response)
    end

    # List tags
    private def list_tags(context : HTTP::Server::Context)
      tags = @site.pages.flat_map(&.tags).uniq.sort

      response = {
        "tags" => tags.map do |tag|
          count = @site.pages.count(&.tags.includes?(tag))
          {"name" => tag, "count" => count}
        end,
      }
      send_json(context, response)
    end

    # Get content by tag
    private def get_tag_content(context : HTTP::Server::Context, tag : String)
      content = @site.pages.select(&.tags.includes?(tag))

      response = {
        "tag"     => tag,
        "content" => content.map { |c| content_to_hash(c) },
        "count"   => content.size,
      }
      send_json(context, response)
    end

    # List categories
    private def list_categories(context : HTTP::Server::Context)
      categories = @site.pages.flat_map(&.categories).uniq.sort

      response = {
        "categories" => categories.map do |category|
          count = @site.pages.count(&.categories.includes?(category))
          {"name" => category, "count" => count}
        end,
      }
      send_json(context, response)
    end

    # Get content by category
    private def get_category_content(context : HTTP::Server::Context, category : String)
      content = @site.pages.select(&.categories.includes?(category))

      response = {
        "category" => category,
        "content"  => content.map { |c| content_to_hash(c) },
        "count"    => content.size,
      }
      send_json(context, response)
    end

    # Build information
    private def build_info(context : HTTP::Server::Context)
      response = {
        "build_config" => {
          "incremental" => @config.build_config.incremental?,
          "parallel"    => @config.build_config.parallel?,
          "output_dir"  => @config.output_dir,
          "cache_dir"   => @config.build_config.cache_dir,
        },
        "last_build"    => @generator.last_build_time.try(&.to_s("%Y-%m-%d %H:%M:%S UTC")),
        "content_count" => @site.pages.size,
      }
      send_json(context, response)
    end

    # Trigger build
    private def trigger_build(context : HTTP::Server::Context)
      spawn do
        @generator.build
      end

      send_json(context, {"message" => "Build triggered successfully"})
    rescue ex
      send_error(context, 500, "Failed to trigger build: #{ex.message}")
    end

    # Analytics information
    private def analytics_info(context : HTTP::Server::Context)
      response = {
        "site_stats" => {
          "total_content"    => @site.pages.size,
          "published_posts"  => @site.pages.count(&.feedable?),
          "draft_content"    => @site.pages.count(&.draft),
          "total_tags"       => @site.pages.flat_map(&.tags).uniq.size,
          "total_categories" => @site.pages.flat_map(&.categories).uniq.size,
        },
        "recent_content" => @site.pages.sort.first(5).map { |c| content_to_hash(c) },
      }
      send_json(context, response)
    end

    # List available functions
    private def list_functions(context : HTTP::Server::Context)
      response = {
        "functions" => Functions.function_list.map do |name|
          {
            "name"      => name,
            "available" => true,
          }
        end,
      }
      send_json(context, response)
    end

    # Get function information
    private def get_function_info(context : HTTP::Server::Context, name : String)
      if Functions.has_function?(name)
        response = {
          "name"        => name,
          "available"   => true,
          "description" => "Function available in Lapis",
        }
        send_json(context, response)
      else
        send_error(context, 404, "Function not found")
      end
    end

    # Execute function
    private def execute_function(context : HTTP::Server::Context, name : String)
      body = context.request.body.try(&.gets_to_end) || "{}"
      data = JSON.parse(body).as_h

      args = data["args"]?.try(&.as_a) || [] of JSON::Any
      args_strings = args.map(&.as_s)

      result = Functions.call(name, args_strings)

      response = {
        "function" => name,
        "args"     => args_strings,
        "result"   => result,
      }
      send_json(context, response)
    rescue ex
      send_error(context, 400, "Failed to execute function: #{ex.message}")
    end

    # Health check
    private def health_check(context : HTTP::Server::Context)
      response = {
        "status"         => "healthy",
        "version"        => Lapis::VERSION,
        "uptime"         => Time.utc.to_s("%Y-%m-%d %H:%M:%S UTC"),
        "content_loaded" => @site.pages.size > 0,
      }
      send_json(context, response)
    end

    # Helper methods

    private def to_json_any(value) : JSON::Any
      case value
      when String
        JSON::Any.new(value)
      when Int32
        JSON::Any.new(value.to_i64)
      when Bool
        JSON::Any.new(value)
      when Array(String)
        JSON::Any.new(value.map { |v| JSON::Any.new(v) })
      when Array(Hash(String, JSON::Any))
        JSON::Any.new(value)
      when Hash(String, String)
        JSON::Any.new(value.transform_values { |v| JSON::Any.new(v) })
      when Hash(String, JSON::Any)
        JSON::Any.new(value)
      when Nil
        JSON::Any.new(nil)
      else
        JSON::Any.new(value.to_s)
      end
    end

    private def content_to_hash(content : Content) : Hash(String, JSON::Any)
      {
        "title"        => JSON::Any.new(content.title),
        "url"          => JSON::Any.new(content.url),
        "file_path"    => JSON::Any.new(content.file_path),
        "layout"       => JSON::Any.new(content.layout),
        "date"         => content.date.try { |d| JSON::Any.new(d.to_s("%Y-%m-%d %H:%M:%S UTC")) } || JSON::Any.new(nil),
        "tags"         => JSON::Any.new(content.tags.map { |tag| JSON::Any.new(tag) }),
        "categories"   => JSON::Any.new(content.categories.map { |cat| JSON::Any.new(cat) }),
        "draft"        => JSON::Any.new(content.draft),
        "description"  => content.description.try { |d| JSON::Any.new(d) } || JSON::Any.new(nil),
        "author"       => content.author.try { |a| JSON::Any.new(a) } || JSON::Any.new(nil),
        "content_type" => JSON::Any.new(content.content_type.to_s),
        "kind"         => JSON::Any.new(content.kind.to_s),
        "section"      => JSON::Any.new(content.section),
        "excerpt"      => JSON::Any.new(content.excerpt(200)),
      }
    end

    private def parse_query_params(context : HTTP::Server::Context) : Hash(String, String)
      params = {} of String => String
      context.request.query_params.each do |key, value|
        params[key] = value
      end
      params
    end

    private def send_json(context : HTTP::Server::Context, data : Hash(String, JSON::Any))
      context.response.content_type = "application/json"
      context.response.status_code = 200
      context.response.print(data.to_json)
    end

    private def send_json(context : HTTP::Server::Context, data : Hash(String, JSON::Any))
      context.response.content_type = "application/json"
      context.response.status_code = 200
      context.response.print(data.to_json)
    end

    private def send_error(context : HTTP::Server::Context, status : Int32, message : String)
      context.response.content_type = "application/json"
      context.response.status_code = status
      context.response.print({
        "error"  => message,
        "status" => status,
      }.to_json)
    end

    private def save_content_to_file(content : Content)
      # Reconstruct the markdown content with frontmatter
      frontmatter = {
        "title"  => content.title,
        "layout" => content.layout,
        "draft"  => content.draft,
      }

      frontmatter["date"] = content.date.to_s("%Y-%m-%d %H:%M:%S UTC") if content.date
      frontmatter["tags"] = content.tags unless content.tags.empty?
      frontmatter["categories"] = content.categories unless content.categories.empty?
      frontmatter["description"] = content.description if content.description
      frontmatter["author"] = content.author if content.author

      yaml_content = frontmatter.to_yaml
      file_content = "---\n#{yaml_content}---\n\n#{content.body}"

      File.write(content.file_path, file_content)
    end
  end
end
