require "yaml"

module Lapis
  class Config
    include YAML::Serializable

    property title : String = "Lapis Site"
    property baseurl : String = "http://localhost:3000"
    property description : String = "A site built with Lapis"
    property author : String = "Site Author"
    property output_dir : String = "public"
    property permalink : String = "/:year/:month/:day/:title/"
    property port : Int32 = 3000
    property host : String = "localhost"

    @[YAML::Field(key: "markdown")]
    property markdown_config : MarkdownConfig?

    def initialize(@title = "Lapis Site", @baseurl = "http://localhost:3000", @description = "A site built with Lapis", @author = "Site Author", @output_dir = "public", @permalink = "/:year/:month/:day/:title/", @port = 3000, @host = "localhost", @markdown_config = nil)
    end

    def self.load(path : String = "config.yml") : Config
      if File.exists?(path)
        content = File.read(path)
        config = from_yaml(content)
        config.validate
        config
      else
        puts "Warning: No config.yml found, using defaults"
        Config.new
      end
    rescue ex : YAML::ParseException
      puts "Error parsing config.yml: #{ex.message}"
      exit(1)
    end

    def validate
      if @output_dir.empty?
        @output_dir = "public"
      end

      if @permalink.empty?
        @permalink = "/:title/"
      end

      if @port < 1 || @port > 65535
        @port = 3000
      end
    end

    def content_dir : String
      "content"
    end

    def layouts_dir : String
      "layouts"
    end

    def static_dir : String
      "static"
    end

    def theme_dir : String
      "themes"
    end

    def posts_dir : String
      File.join(content_dir, "posts")
    end

    def server_url : String
      "#{host}:#{port}"
    end

    def markdown : MarkdownConfig
      @markdown_config ||= MarkdownConfig.new(
        syntax_highlighting: true,
        toc: true,
        smart_quotes: true,
        footnotes: true,
        tables: true
      )
    end
  end

  class MarkdownConfig
    include YAML::Serializable

    property syntax_highlighting : Bool = true
    property toc : Bool = true
    property smart_quotes : Bool = true
    property footnotes : Bool = true
    property tables : Bool = true

    def initialize(@syntax_highlighting = true, @toc = true, @smart_quotes = true, @footnotes = true, @tables = true)
    end
  end
end