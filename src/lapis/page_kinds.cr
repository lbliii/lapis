module Lapis
  # Page kinds define the type of page being rendered
  enum PageKind
    # Individual content pages (blog posts, articles, etc.)
    Single

    # Archive pages that list multiple items
    List

    # Directory-based content grouping (e.g., /posts/, /projects/)
    Section

    # Category/tag listing pages (e.g., /tags/)
    Taxonomy

    # Individual taxonomy pages (e.g., /tags/crystal/)
    Term

    # Site homepage (special case of list)
    Home

    def to_s(format : IO) : Nil
      format << self.to_s.downcase
    end

    def to_s : String
      case self
      when .single?
        "single"
      when .list?
        "list"
      when .section?
        "section"
      when .taxonomy?
        "taxonomy"
      when .term?
        "term"
      when .home?
        "home"
      else
        "single"
      end
    end
  end

  # Detects page kind based on file path and content structure
  class PageKindDetector
    def self.detect(file_path : String, content_dir : String) : PageKind
      # Normalize paths for comparison
      rel_path = Path[file_path].relative_to(Path[content_dir]).to_s
      dir_parts = Path[rel_path].parts[0..-2] # All parts except filename
      filename = Path[file_path].basename

      # Home page detection
      if filename == "index.md" && dir_parts.empty?
        return PageKind::Home
      end

      # Section detection - _index.md files create section pages
      if filename == "_index.md"
        return PageKind::Section
      end

      # Taxonomy detection - files in taxonomies directory
      if dir_parts.includes?("taxonomies") || dir_parts.includes?("tags") || dir_parts.includes?("categories")
        if filename == "_index.md"
          return PageKind::Taxonomy
        else
          return PageKind::Term
        end
      end

      # List detection - any other _index.md file creates a list page
      if filename == "_index.md"
        return PageKind::List
      end

      # Default to single page for individual content files
      PageKind::Single
    end

    # Detects section name from file path
    def self.detect_section(file_path : String, content_dir : String) : String
      rel_path = Path[file_path].relative_to(Path[content_dir]).to_s
      dir_parts = Path[rel_path].parts[0..-2] # All parts except filename

      return "" if dir_parts.empty?

      # Return the first directory as the section
      dir_parts[0]
    end

    # Determines if a path represents a content section directory
    def self.section_dir?(dir_path : String, content_dir : String) : Bool
      return false unless Dir.exists?(dir_path)

      # Check if directory contains markdown files or an _index.md
      has_content = Dir.glob(File.join(dir_path, "*.md")).any?
      has_index = File.exists?(File.join(dir_path, "_index.md"))

      has_content || has_index
    end
  end
end
