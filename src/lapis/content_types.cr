module Lapis
  # Content types define the semantic type of content
  enum ContentType
    # Regular pages (about, contact, etc.)
    Page

    # Blog posts and articles
    Article

    # Documentation pages
    Documentation

    # Glossary entries
    Glossary

    # Project pages
    Project

    # News/announcement posts
    News

    def to_s(format : IO) : Nil
      format << self.to_s.downcase
    end

    def to_s : String
      case self
      when .page?
        "page"
      when .article?
        "article"
      when .documentation?
        "documentation"
      when .glossary?
        "glossary"
      when .project?
        "project"
      when .news?
        "news"
      else
        "page"
      end
    end

    # Check if this content type should be included in feeds
    def feedable? : Bool
      case self
      when .article?, .news?
        true
      else
        false
      end
    end

    # Check if this content type should use date-based URLs
    def date_based_url? : Bool
      case self
      when .article?, .news?
        true
      else
        false
      end
    end

    # Get the default layout for this content type
    def default_layout : String
      case self
      when .article?, .news?
        "post"
      when .documentation?
        "documentation"
      when .glossary?
        "glossary"
      when .project?
        "project"
      else
        "page"
      end
    end

    # Get the default directory for this content type
    def default_directory : String
      case self
      when .article?
        "posts"
      when .news?
        "news"
      when .documentation?
        "docs"
      when .glossary?
        "glossary"
      when .project?
        "projects"
      else
        ""
      end
    end

    # Parse content type from string (case insensitive)
    def self.parse(type_string : String) : ContentType
      case type_string.downcase
      when "page"
        ContentType::Page
      when "article", "post"
        ContentType::Article
      when "documentation", "docs", "doc"
        ContentType::Documentation
      when "glossary"
        ContentType::Glossary
      when "project"
        ContentType::Project
      when "news"
        ContentType::News
      else
        ContentType::Page
      end
    end
  end

  # Content type configuration
  class ContentTypeConfig
    include YAML::Serializable

    @[YAML::Field(emit_null: true)]
    property feedable_types : Array(String) = ["article", "news"]

    @[YAML::Field(emit_null: true)]
    property date_based_types : Array(String) = ["article", "news"]

    @[YAML::Field(emit_null: true)]
    property type_mappings : Hash(String, String) = {
      "post" => "article",
      "docs" => "documentation",
      "doc"  => "documentation",
    }

    @[YAML::Field(emit_null: true)]
    property directory_mappings : Hash(String, String) = {
      "article"       => "posts",
      "news"          => "news",
      "documentation" => "docs",
      "glossary"      => "glossary",
      "project"       => "projects",
    }

    @[YAML::Field(emit_null: true)]
    property layout_mappings : Hash(String, String) = {
      "article"       => "post",
      "news"          => "post",
      "documentation" => "documentation",
      "glossary"      => "glossary",
      "project"       => "project",
    }

    def initialize
    end

    # Check if a content type should be included in feeds
    def feedable?(content_type : String) : Bool
      @feedable_types.includes?(content_type.downcase)
    end

    # Check if a content type should use date-based URLs
    def date_based_url?(content_type : String) : Bool
      @date_based_types.includes?(content_type.downcase)
    end

    # Get the mapped content type (handles aliases)
    def map_type(type_string : String) : String
      @type_mappings[type_string.downcase]? || type_string.downcase
    end

    # Get the default directory for a content type
    def get_directory(content_type : String) : String
      @directory_mappings[content_type.downcase]? || ""
    end

    # Get the default layout for a content type
    def get_layout(content_type : String) : String
      @layout_mappings[content_type.downcase]? || "page"
    end
  end
end
