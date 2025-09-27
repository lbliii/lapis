require "./spec_helper"

describe Lapis do
  it "has correct version" do
    Lapis::VERSION.should eq("0.1.0")
  end
end

describe Lapis::Config do
  it "loads with defaults" do
    config = Lapis::Config.new
    config.title.should eq("Lapis Site")
    config.port.should eq(3000)
    config.output_dir.should eq("public")
  end

  it "validates configuration" do
    config = Lapis::Config.new
    config.output_dir = ""
    config.validate
    config.output_dir.should eq("public")
  end
end

describe Lapis::Content do
  it "creates content from frontmatter and body" do
    frontmatter = sample_frontmatter
    body = sample_markdown_content

    content = Lapis::Content.new("test.md", frontmatter, body)

    content.title.should eq("Sample Post")
    content.layout.should eq("post")
    content.tags.should eq(["crystal", "lapis"])
    content.content.should contain("<h1>Sample Post</h1>")
  end

  it "generates correct URLs for posts" do
    frontmatter = sample_frontmatter
    body = sample_markdown_content

    content = Lapis::Content.new("content/posts/sample.md", frontmatter, body)
    content.url.should eq("/2024/01/15/sample/")
  end

  it "generates correct URLs for pages" do
    frontmatter = sample_frontmatter
    body = sample_markdown_content

    content = Lapis::Content.new("content/about.md", frontmatter, body)
    content.url.should eq("/about/")
  end
end