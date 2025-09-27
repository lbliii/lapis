require "yaml"
require "markd"

module Lapis
  class Content
    property title : String
    property layout : String
    property date : Time?
    property tags : Array(String)
    property categories : Array(String)
    property permalink : String?
    property draft : Bool
    property description : String?
    property author : String?
    property toc : Bool
    property frontmatter : Hash(String, YAML::Any)
    property body : String
    property content : String
    property raw_content : String
    property file_path : String
    property url : String

    def initialize(@file_path : String, @frontmatter : Hash(String, YAML::Any), @body : String)
      @title = @frontmatter["title"]?.try(&.as_s) || File.basename(@file_path, ".md").humanize
      @layout = @frontmatter["layout"]?.try(&.as_s) || "default"
      @date = parse_date(@frontmatter["date"]?)
      @tags = parse_array(@frontmatter["tags"]?)
      @categories = parse_array(@frontmatter["categories"]?)
      @permalink = @frontmatter["permalink"]?.try(&.as_s)
      @draft = @frontmatter["draft"]?.try(&.as_bool) || false
      @description = @frontmatter["description"]?.try(&.as_s)
      @author = @frontmatter["author"]?.try(&.as_s)
      @toc = @frontmatter["toc"]?.try(&.as_bool) || true
      @raw_content = @body
      @content = process_markdown(@body)
      @url = generate_url
    end

    def self.load(file_path : String) : Content
      content = File.read(file_path)
      frontmatter, body = parse_frontmatter(content)
      new(file_path, frontmatter, body)
    end

    def self.load_all(directory : String) : Array(Content)
      content = [] of Content

      if Dir.exists?(directory)
        Dir.glob(File.join(directory, "**", "*.md")).each do |file_path|
          begin
            content << load(file_path)
          rescue ex
            puts "Warning: Could not load #{file_path}: #{ex.message}"
          end
        end
      end

      content.sort_by(&.date).reverse
    end

    def self.create_new(type : String, title : String)
      filename = title.downcase.gsub(/[^a-z0-9]+/, "-").strip("-")

      case type
      when "post"
        dir = "content/posts"
        path = File.join(dir, "#{filename}.md")
        layout = "post"
      else
        dir = "content"
        path = File.join(dir, "#{filename}.md")
        layout = "page"
      end

      Dir.mkdir_p(dir)

      content = "---\n"
      content += "title: \"#{title}\"\n"
      content += "date: \"#{Time.utc.to_s("%Y-%m-%d %H:%M:%S UTC")}\"\n"
      content += "layout: \"#{layout}\"\n"
      content += "draft: false\n"

      if type == "post"
        content += "tags: []\n"
      end
      content += "---\n\n"
      content += "# #{title}\n\n"
      content += "Write your content here...\n"

      File.write(path, content)
      puts "Created #{path}"
    end

    def is_post? : Bool
      @file_path.includes?("/posts/")
    end

    def is_page? : Bool
      !is_post?
    end

    def excerpt(length : Int32 = 200) : String
      text = @content.gsub(/<[^>]*>/, "")
      if text.size <= length
        text
      else
        text[0...length] + "..."
      end
    end

    private def self.parse_frontmatter(content : String) : Tuple(Hash(String, YAML::Any), String)
      if content.starts_with?("---\n")
        parts = content.split("---\n", 3)
        if parts.size >= 3
          frontmatter_yaml = parts[1]
          body = parts[2]

          frontmatter = Hash(String, YAML::Any).new
          if !frontmatter_yaml.strip.empty?
            parsed = YAML.parse(frontmatter_yaml)
            if parsed.as_h?
              frontmatter = parsed.as_h.transform_keys(&.to_s)
            end
          end

          return {frontmatter, body}
        end
      end

      {Hash(String, YAML::Any).new, content}
    end

    private def process_markdown(markdown : String, config : Config) : String
      # First process shortcodes, then convert markdown
      processor = ShortcodeProcessor.new(config)
      processed_markdown = processor.process(markdown)

      options = Markd::Options.new(
        smart: true,
        safe: false
      )

      Markd.to_html(processed_markdown, options)
    end

    private def parse_date(date_value : YAML::Any?) : Time?
      return nil unless date_value

      date_str = date_value.as_s
      begin
        Time.parse(date_str, "%Y-%m-%d", Time::Location::UTC)
      rescue Time::Format::Error
        begin
          Time.parse(date_str, "%Y-%m-%d %H:%M:%S UTC", Time::Location::UTC)
        rescue Time::Format::Error
          nil
        end
      end
    end

    private def parse_array(value : YAML::Any?) : Array(String)
      return [] of String unless value

      if array = value.as_a?
        array.map(&.as_s)
      elsif string = value.as_s?
        [string]
      else
        [] of String
      end
    end

    private def generate_url : String
      if @permalink
        return @permalink.not_nil!
      end

      if is_post? && @date
        date = @date.not_nil!
        year = date.year.to_s
        month = date.month.to_s.rjust(2, '0')
        day = date.day.to_s.rjust(2, '0')
        slug = File.basename(@file_path, ".md")
        "/#{year}/#{month}/#{day}/#{slug}/"
      else
        slug = File.basename(@file_path, ".md")
        if slug == "index"
          "/"
        else
          "/#{slug}/"
        end
      end
    end
  end
end

# String extension for humanizing filenames
class String
  def humanize
    self.gsub(/[-_]/, " ").split.map(&.capitalize).join(" ")
  end
end