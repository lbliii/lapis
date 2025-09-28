require "../spec_helper"

describe Lapis::Content do
  describe ".load" do
    it "loads content from file", tags: [TestTags::FAST, TestTags::UNIT] do
      content_text = <<-MD
      ---
      title: Test Post
      date: 2024-01-15
      tags: [test, crystal]
      layout: post
      ---

      # Test Post

      This is test content.
      MD

      with_temp_file(content_text) do |file_path|
        content = Lapis::Content.load(file_path)

        content.title.should eq("Test Post")
        content.layout.should eq("post")
        content.tags.should eq(["test", "crystal"])
        content.content.should contain("Test Post")
      end
    end

    it "handles missing files gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      expect_raises(Lapis::ContentError) do
        Lapis::Content.load("nonexistent.md")
      end
    end

    it "handles invalid YAML gracefully", tags: [TestTags::FAST, TestTags::UNIT] do
      content_text = <<-MD
      ---
      title: Test Post
      invalid: yaml: content: here
      ---

      Content here
      MD

      with_temp_file(content_text) do |file_path|
        expect_raises(Lapis::ContentError) do
          Lapis::Content.load(file_path)
        end
      end
    end
  end

  describe "#url" do
    it "generates correct URL for posts using Path", tags: [TestTags::FAST, TestTags::UNIT] do
      frontmatter = TestDataFactory.create_content("Test Post", "2024-01-15", ["test"], "post")
      content = Lapis::Content.new("content/posts/test.md", frontmatter, "content")

      content.url.should eq("/2024/01/15/test/")
    end

    it "generates correct URL for pages using Path", tags: [TestTags::FAST, TestTags::UNIT] do
      frontmatter = TestDataFactory.create_content("About", "", ["test"], "page")
      content = Lapis::Content.new("content/about.md", frontmatter, "content")

      content.url.should eq("/about/")
    end

    it "handles index files correctly with Path", tags: [TestTags::FAST, TestTags::UNIT] do
      frontmatter = TestDataFactory.create_content("Index Page", "", ["test"], "page")
      content = Lapis::Content.new("content/index.md", frontmatter, "content")

      content.url.should eq("/")
    end

    it "handles nested paths correctly with Path", tags: [TestTags::FAST, TestTags::UNIT] do
      frontmatter = TestDataFactory.create_content("Nested Page", "", ["test"], "page")
      content = Lapis::Content.new("content/docs/api/reference.md", frontmatter, "content")

      content.url.should eq("/docs/api/reference/")
    end
  end

  describe "#title" do
    it "generates title from filename using Path", tags: [TestTags::FAST, TestTags::UNIT] do
      frontmatter = {} of String => YAML::Any # No title in frontmatter
      content = Lapis::Content.new("content/my-awesome-post.md", frontmatter, "content")

      content.title.should eq("My Awesome Post")
    end

    it "uses frontmatter title when available", tags: [TestTags::FAST, TestTags::UNIT] do
      frontmatter = TestDataFactory.create_content("Custom Title")
      content = Lapis::Content.new("content/some-file.md", frontmatter, "content")

      content.title.should eq("Custom Title")
    end

    it "handles complex filenames with Path", tags: [TestTags::FAST, TestTags::UNIT] do
      frontmatter = {} of String => YAML::Any # No title in frontmatter
      content = Lapis::Content.new("content/api-v2-reference-guide.md", frontmatter, "content")

      content.title.should eq("Api V2 Reference Guide")
    end
  end

  describe "#excerpt" do
    it "generates excerpt from content", tags: [TestTags::FAST, TestTags::UNIT] do
      frontmatter = TestDataFactory.create_content("Test Post")
      body = "This is a long piece of content that should be truncated when generating an excerpt for display purposes."
      content = Lapis::Content.new("test.md", frontmatter, body)

      excerpt = content.excerpt(20)
      excerpt.size.should be <= 23 # Allow for some flexibility
      excerpt.should contain("This is a long")
    end
  end

  describe "#kind" do
    it "detects post kind correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      frontmatter = TestDataFactory.create_content("Test Post")
      content = Lapis::Content.new("content/posts/test.md", frontmatter, "content")

      content.kind.should eq(Lapis::PageKind::Single)
    end

    it "detects page kind correctly", tags: [TestTags::FAST, TestTags::UNIT] do
      frontmatter = TestDataFactory.create_content("About")
      content = Lapis::Content.new("content/about.md", frontmatter, "content")

      content.kind.should eq(Lapis::PageKind::Single)
    end
  end

  describe ".load_all" do
    it "loads all content from directory", tags: [TestTags::INTEGRATION] do
      with_temp_directory do |temp_dir|
        # Create test content files
        content_dir = File.join(temp_dir, "content")
        Dir.mkdir(content_dir)

        # Create sample files
        3.times do |i|
          content_text = <<-MD
          ---
          title: Post #{i + 1}
          date: 2024-01-#{15 + i}
          ---

          Content #{i + 1}
          MD

          File.write(File.join(content_dir, "post-#{i + 1}.md"), content_text)
        end

        content = Lapis::Content.load_all(content_dir)

        content.size.should eq(3)
        content.first.title.should eq("Post 3") # Should be sorted by date desc
      end
    end

    it "handles empty directory", tags: [TestTags::FAST, TestTags::UNIT] do
      with_temp_directory do |temp_dir|
        content = Lapis::Content.load_all(temp_dir)
        content.should be_empty
      end
    end

    it "handles non-existent directory", tags: [TestTags::FAST, TestTags::UNIT] do
      content = Lapis::Content.load_all("nonexistent")
      content.should be_empty
    end
  end
end
