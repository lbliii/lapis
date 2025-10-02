require "json"
require "yaml"
require "./content"
require "./site"
require "./generator"
require "./config"
require "./logger"

module Lapis
  # Simple REST API for Lapis content management
  class SimpleAPI
    property config : Config
    property generator : Generator
    property site : Site

    def initialize(@config : Config, @generator : Generator)
      @site = Site.new(@config)
    end

    # Initialize with loaded content
    def self.with_content(config : Config, generator : Generator, content : Array(Content))
      api = new(config, generator)
      api.site = Site.new(config, content)
      api
    end

    # Main API handler
    def handle_request(context : HTTP::Server::Context) : Bool
      path = context.request.path
      method = context.request.method

      case {method, path}
      when {"GET", "/api"}
        api_info(context)
        true
      when {"GET", "/api/site"}
        site_info(context)
        true
      when {"GET", "/api/content"}
        list_content(context)
        true
      when {"GET", "/api/health"}
        health_check(context)
        true
      else
        false # Not an API route
      end
    end

    private def api_info(context : HTTP::Server::Context)
      response = {
        "name"        => "Lapis API",
        "version"     => Lapis::VERSION,
        "description" => "REST API for Lapis static site generator",
        "endpoints"   => [
          "/api",
          "/api/site",
          "/api/content",
          "/api/health",
        ],
      }
      send_json(context, response)
    end

    private def site_info(context : HTTP::Server::Context)
      response = {
        "title"         => @site.title,
        "description"   => @site.description,
        "base_url"      => @site.base_url,
        "author"        => @site.author,
        "language"      => @site.language_code,
        "theme"         => @site.theme,
        "content_count" => @site.pages.size,
      }
      send_json(context, response)
    end

    private def list_content(context : HTTP::Server::Context)
      content = @site.pages.first(10) # Limit to first 10 for now
      response = {
        "content" => content.map { |c| content_summary(c) },
        "total"   => @site.pages.size,
        "showing" => content.size,
      }
      send_json(context, response)
    end

    private def health_check(context : HTTP::Server::Context)
      response = {
        "status"         => "healthy",
        "version"        => Lapis::VERSION,
        "content_loaded" => @site.pages.size > 0,
        "timestamp"      => Time.utc.to_s("%Y-%m-%d %H:%M:%S UTC"),
      }
      send_json(context, response)
    end

    private def content_summary(content : Content) : Hash(String, String)
      {
        "title"   => content.title,
        "url"     => content.url,
        "layout"  => content.layout,
        "date"    => content.date.try(&.to_s("%Y-%m-%d")) || "",
        "draft"   => content.draft.to_s,
        "tags"    => content.tags.join(", "),
        "excerpt" => content.excerpt(100),
      }
    end

    private def send_json(context : HTTP::Server::Context, data)
      context.response.content_type = "application/json"
      context.response.status_code = 200
      context.response.print(data.to_json)
    end
  end
end
