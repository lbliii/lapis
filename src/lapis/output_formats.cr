require "./page_kinds"

module Lapis
  # Represents a media type for output formats
  struct MediaType
    include YAML::Serializable

    property name : String
    property type : String
    property subtype : String
    property suffixes : Array(String)
    property delimiter : String

    def initialize(@name : String, @type : String, @subtype : String, @suffixes : Array(String), @delimiter : String = "")
    end

    def to_s(io)
      io << "#{@type}/#{@subtype}"
    end

    def to_s : String
      "#{@type}/#{@subtype}"
    end

    def self.builtin
      {
        "html" => MediaType.new(
          name: "html",
          type: "text",
          subtype: "html",
          suffixes: ["html"],
          delimiter: ""
        ),
        "json" => MediaType.new(
          name: "json",
          type: "application",
          subtype: "json",
          suffixes: ["json"],
          delimiter: ""
        ),
        "rss" => MediaType.new(
          name: "rss",
          type: "application",
          subtype: "rss+xml",
          suffixes: ["xml"],
          delimiter: ""
        ),
        "text" => MediaType.new(
          name: "text",
          type: "text",
          subtype: "plain",
          suffixes: ["txt"],
          delimiter: ""
        ),
        "sitemap" => MediaType.new(
          name: "sitemap",
          type: "application",
          subtype: "xml",
          suffixes: ["xml"],
          delimiter: ""
        ),
        "atom" => MediaType.new(
          name: "atom",
          type: "application",
          subtype: "atom+xml",
          suffixes: ["xml"],
          delimiter: ""
        ),
      }
    end
  end

  # Defines how content is output in different formats
  struct OutputFormat
    include YAML::Serializable

    property name : String
    property media_type : MediaType
    property base_name : String
    property extension : String
    property is_html : Bool
    property is_plain_text : Bool
    property no_ugly : Bool
    property weight : Int32
    property rel : String
    property protocol : String

    def initialize(@name : String, @media_type : MediaType, @base_name : String = "index",
                   extension : String? = nil, @is_html : Bool = false, @is_plain_text : Bool = false,
                   @no_ugly : Bool = false, @weight : Int32 = 0, @rel : String = "alternate",
                   @protocol : String = "")
      @extension = extension || @media_type.suffixes.first? || "html"
    end

    def filename(page_name : String = "") : String
      if page_name.empty?
        "#{@base_name}.#{@extension}"
      else
        "#{page_name}.#{@name}.#{@extension}"
      end
    end

    def self.builtin
      media_types = MediaType.builtin
      {
        "html" => OutputFormat.new(
          name: "html",
          media_type: media_types["html"],
          base_name: "index",
          extension: "html",
          is_html: true,
          weight: 10,
          rel: "canonical"
        ),
        "json" => OutputFormat.new(
          name: "json",
          media_type: media_types["json"],
          base_name: "index",
          extension: "json",
          is_plain_text: true,
          weight: 20
        ),
        "rss" => OutputFormat.new(
          name: "rss",
          media_type: media_types["rss"],
          base_name: "index",
          extension: "xml",
          is_plain_text: true,
          weight: 30
        ),
        "llm" => OutputFormat.new(
          name: "llm",
          media_type: media_types["text"],
          base_name: "llm",
          extension: "txt",
          is_plain_text: true,
          weight: 40
        ),
        "sitemap" => OutputFormat.new(
          name: "sitemap",
          media_type: media_types["sitemap"],
          base_name: "sitemap",
          extension: "xml",
          is_plain_text: true,
          weight: 50
        ),
      }
    end
  end

  # Manages output format configuration and resolution
  class OutputFormatManager
    include YAML::Serializable

    property formats : Hash(String, OutputFormat)
    property outputs_by_kind : Hash(PageKind, Array(String))

    def initialize
      @formats = OutputFormat.builtin
      @outputs_by_kind = default_outputs_by_kind
    end

    def add_format(name : String, format : OutputFormat)
      @formats[name] = format
    end

    def get_format(name : String) : OutputFormat?
      @formats[name]?
    end

    def formats_for_kind(kind : PageKind) : Array(OutputFormat)
      format_names = @outputs_by_kind[kind]? || ["html"]
      format_names.compact_map { |name| @formats[name]? }
    end

    def set_outputs_for_kind(kind : PageKind, format_names : Array(String))
      @outputs_by_kind[kind] = format_names
    end

    def load_from_config(config : Hash(String, YAML::Any))
      # Load custom output formats
      if output_formats = config["output_formats"]?.try(&.as_h?)
        output_formats.each do |name, format_config|
          load_format_from_config(name.as_s, format_config.as_h.transform_keys(&.to_s))
        end
      end

      # Load outputs configuration
      if outputs = config["outputs"]?.try(&.as_h?)
        outputs.each do |kind_str, formats_config|
          if kind = parse_page_kind(kind_str.as_s)
            format_names = formats_config.as_a.map(&.as_s)
            set_outputs_for_kind(kind, format_names)
          end
        end
      end
    end

    private def default_outputs_by_kind : Hash(PageKind, Array(String))
      {
        PageKind::Home     => ["html", "rss"],
        PageKind::Single   => ["html", "json"],
        PageKind::List     => ["html", "rss"],
        PageKind::Section  => ["html", "rss"],
        PageKind::Taxonomy => ["html"],
        PageKind::Term     => ["html", "rss"],
      }
    end

    private def load_format_from_config(name : String, config : Hash(String, YAML::Any))
      media_type_name = config["media_type"]?.try(&.as_s) || "html"
      media_type = MediaType.builtin[media_type_name]? || MediaType.builtin["html"]

      format = OutputFormat.new(
        name: name,
        media_type: media_type,
        base_name: config["base_name"]?.try(&.as_s) || "index",
        extension: config["extension"]?.try(&.as_s),
        is_html: config["is_html"]?.try(&.as_bool) || false,
        is_plain_text: config["is_plain_text"]?.try(&.as_bool) || false,
        no_ugly: config["no_ugly"]?.try(&.as_bool) || false,
        weight: config["weight"]?.try(&.as_i) || 0,
        rel: config["rel"]?.try(&.as_s) || "alternate"
      )

      add_format(name, format)
    end

    private def parse_page_kind(kind_str : String) : PageKind?
      case kind_str.downcase
      when "home"
        PageKind::Home
      when "single"
        PageKind::Single
      when "list"
        PageKind::List
      when "section"
        PageKind::Section
      when "taxonomy"
        PageKind::Taxonomy
      when "term"
        PageKind::Term
      else
        nil
      end
    end
  end
end
