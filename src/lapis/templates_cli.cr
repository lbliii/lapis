module Lapis
  # Template manager for creating sites from predefined templates
  #
  # Standard: Use "exampleSite" directory for the official example/demo site
  # This follows Hugo's convention and provides a single reference implementation
  class TemplateManager
    BUILTIN_TEMPLATES = {
      "blog" => {
        "name" => "Personal Blog",
        "description" => "A clean, responsive blog template perfect for personal writing",
        "files" => ["config.yml", "content/index.md", "content/about.md", "content/posts/welcome.md", "static/css/blog.css"]
      },
      "docs" => {
        "name" => "Documentation Site",
        "description" => "Technical documentation template with sidebar navigation",
        "files" => ["config.yml", "content/index.md", "content/getting-started.md", "content/api/overview.md", "static/css/docs.css"]
      },
      "portfolio" => {
        "name" => "Portfolio Site",
        "description" => "Showcase your work with this portfolio template",
        "files" => ["config.yml", "content/index.md", "content/portfolio/project1.md", "static/css/portfolio.css"]
      },
      "minimal" => {
        "name" => "Minimal Site",
        "description" => "Ultra-clean template focusing on content",
        "files" => ["config.yml", "content/index.md", "static/css/minimal.css"]
      }
    }

    def self.list_templates
      puts "Available templates:"
      puts ""

      BUILTIN_TEMPLATES.each do |key, template|
        puts "  #{key.ljust(12)} #{template["name"]}"
        puts "  #{"".ljust(12)} #{template["description"]}"
        puts ""
      end
    end

    def self.create_from_template(template_name : String, site_name : String)
      template = BUILTIN_TEMPLATES[template_name]?
      unless template
        puts "Error: Template '#{template_name}' not found"
        puts "Available templates: #{BUILTIN_TEMPLATES.keys.join(", ")}"
        exit(1)
      end

      puts "Creating site '#{site_name}' from #{template["name"]} template..."

      begin
        Dir.mkdir(site_name)
        Dir.cd(site_name) do
          case template_name
          when "blog"
            create_blog_template
          when "docs"
            create_docs_template
          when "portfolio"
            create_portfolio_template
          when "minimal"
            create_minimal_template
          end
        end

        puts "✅ Site '#{site_name}' created successfully!"
        puts ""
        puts "Next steps:"
        puts "  cd #{site_name}"
        puts "  lapis serve"
        puts ""
        puts "Template features:"
        puts "  • #{template["description"]}"
        puts "  • Responsive design"
        puts "  • Dark mode support"
        puts "  • SEO optimized"

      rescue File::AlreadyExistsError
        puts "Error: Directory '#{site_name}' already exists"
        exit(1)
      end
    end

    private def self.create_blog_template
      create_directories(["content", "content/posts", "layouts", "static", "static/css", "static/js", "static/images"])

      # Enhanced blog config
      config_content = <<-YAML
      title: "My Blog"
      baseurl: "http://localhost:3000"
      description: "Thoughts, stories, and ideas from a digital wanderer"
      author: "Your Name"

      # Blog-specific settings
      posts_per_page: 10
      excerpt_length: 200
      show_reading_time: true

      # Social links
      social:
        twitter: "yourusername"
        github: "yourusername"
        email: "you@example.com"

      # SEO settings
      google_analytics: ""
      facebook_app_id: ""

      # Build settings
      output_dir: "public"
      permalink: "/:year/:month/:day/:title/"

      # Server settings
      port: 3000
      host: "localhost"

      # Advanced features
      markdown:
        syntax_highlighting: true
        toc: true
        smart_quotes: true
        footnotes: true
      YAML

      File.write("config.yml", config_content)

      # Enhanced index page
      index_content = <<-MD
      ---
      title: "Welcome to My Blog"
      layout: "home"
      description: "A place where thoughts meet pixels and ideas come alive"
      ---

      # Welcome to My Blog 👋

      Hello! I'm excited to share my thoughts, experiences, and discoveries with you. This is where I write about technology, life, and everything in between.

      ## Recent Posts

      {% recent_posts 5 %}

      ## What You'll Find Here

      - 💡 **Tech Insights**: Deep dives into development, tools, and emerging technologies
      - 🌱 **Personal Growth**: Reflections on learning, productivity, and life lessons
      - 🎨 **Creative Projects**: Showcasing interesting builds and experiments
      - 📚 **Book Reviews**: Thoughts on influential reads

      ## Let's Connect

      I love connecting with fellow readers and writers. Feel free to reach out!

      - Follow me on [Twitter](https://twitter.com/yourusername)
      - Check out my code on [GitHub](https://github.com/yourusername)
      - Send me an [email](mailto:you@example.com)

      ---

      *This blog is powered by [Lapis](https://github.com/lapis-lang/lapis), a fast static site generator built with Crystal.*
      MD

      File.write("content/index.md", index_content)

      # Enhanced about page
      about_content = <<-MD
      ---
      title: "About Me"
      layout: "page"
      description: "Learn more about the person behind the blog"
      ---

      # About Me

      Hi there! I'm a passionate developer, writer, and lifelong learner. Welcome to my corner of the internet.

      ## My Story

      I started this blog to document my journey in tech and share insights that might help others along the way. What began as personal notes has evolved into a platform for meaningful conversations about technology, creativity, and growth.

      ## What I Do

      - 💻 **Software Development**: I build web applications and enjoy exploring new technologies
      - ✍️ **Writing**: I believe in the power of clear communication and love sharing knowledge
      - 🎓 **Learning**: Always curious, always growing, always experimenting

      ## Technical Interests

      - Modern web development (Crystal, TypeScript, etc.)
      - Performance optimization and scalability
      - Developer experience and tooling
      - Open source contribution

      ## Beyond Code

      When I'm not coding or writing, you might find me:

      - 📚 Reading science fiction or technical books
      - 🎵 Discovering new music
      - 🌲 Hiking or exploring nature
      - ☕ Trying new coffee shops

      ## Get In Touch

      I'm always interested in connecting with fellow developers, writers, and curious minds. Feel free to reach out!

      **Email**: [you@example.com](mailto:you@example.com)
      **Twitter**: [@yourusername](https://twitter.com/yourusername)
      **GitHub**: [yourusername](https://github.com/yourusername)

      ---

      *Want to start your own blog? This site is built with [Lapis](https://github.com/lapis-lang/lapis) – it's fast, flexible, and fun to use!*
      MD

      File.write("content/about.md", about_content)

      # Sample blog post with advanced features
      first_post = <<-MD
      ---
      title: "Welcome to My New Blog!"
      date: "#{Time.utc.to_s("%Y-%m-%d %H:%M:%S UTC")}"
      tags: ["welcome", "blogging", "lapis"]
      categories: ["meta"]
      layout: "post"
      description: "The story behind this blog and what you can expect to find here"
      author: "Your Name"
      reading_time: 3
      featured: true
      ---

      # Welcome to My New Blog! 🎉

      After months of thinking about it, I've finally launched my personal blog! This first post is both an introduction and a commitment to sharing my journey in tech, writing, and life.

      ## Why Start a Blog?

      In our fast-paced digital world, I believe there's immense value in slowing down to reflect and share. Here are the main reasons I decided to start writing:

      ### 1. **Learning in Public**
      {% alert "info" %}
      The best way to solidify knowledge is to teach it to others.
      {% endalert %}

      By writing about what I learn, I force myself to truly understand concepts and can help others who might be on similar journeys.

      ### 2. **Building Connections**
      The tech community is incredibly welcoming, and I want to contribute to the conversations that have helped me grow.

      ### 3. **Documenting Growth**
      {% quote "Maya Angelou" "Letter to My Daughter" %}
      There is no greater agony than bearing an untold story inside you.
      {% endquote %}

      Everyone has unique experiences and perspectives worth sharing.

      ## What to Expect

      I plan to write about:

      - **Technical deep-dives**: Exploring interesting problems and solutions
      - **Tool reviews**: Sharing thoughts on development tools and workflows
      - **Personal projects**: Documenting builds and experiments
      - **Industry reflections**: Thoughts on tech trends and culture

      ## The Tech Behind This Blog

      This blog is built with [Lapis](https://github.com/lapis-lang/lapis), a modern static site generator written in Crystal. Why Lapis?

      ```crystal
      # Fast builds with Crystal's performance
      def generate_site
        content = load_markdown_files
        html = process_templates(content)
        write_output(html)
      end
      ```

      - ⚡ **Lightning fast** builds
      - 🎨 **Flexible** templating system
      - 📱 **Responsive** by default
      - 🔧 **Developer-friendly** workflow

      ## Let's Connect!

      I'm excited to start this journey and would love to connect with fellow developers, writers, and curious minds.

      {% button "https://twitter.com/yourusername" "Follow on Twitter" "primary" %}

      What topics would you like me to write about? Drop me a line and let me know!

      ---

      *Thanks for reading, and welcome to the blog! 🙏*
      MD

      File.write("content/posts/welcome.md", first_post)

      # Enhanced CSS for blog
      blog_css = <<-CSS
      /* Enhanced Blog Theme for Lapis */

      :root {
        --primary-color: #667eea;
        --secondary-color: #764ba2;
        --accent-color: #f093fb;
        --text-color: #2d3748;
        --text-light: #718096;
        --bg-color: #ffffff;
        --bg-secondary: #f7fafc;
        --border-color: #e2e8f0;
        --success-color: #48bb78;
        --warning-color: #ed8936;
        --error-color: #f56565;
        --code-bg: #1a202c;
        --code-text: #e2e8f0;
      }

      @media (prefers-color-scheme: dark) {
        :root {
          --text-color: #f7fafc;
          --text-light: #a0aec0;
          --bg-color: #1a202c;
          --bg-secondary: #2d3748;
          --border-color: #4a5568;
        }
      }

      * {
        box-sizing: border-box;
      }

      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        line-height: 1.7;
        color: var(--text-color);
        background: var(--bg-color);
        margin: 0;
        padding: 0;
      }

      /* Enhanced Navigation */
      .site-header {
        background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
        color: white;
        padding: 2rem 0;
        margin-bottom: 3rem;
      }

      .site-nav {
        max-width: 1200px;
        margin: 0 auto;
        padding: 0 2rem;
        display: flex;
        justify-content: space-between;
        align-items: center;
      }

      .site-title {
        font-size: 1.8rem;
        font-weight: 700;
        color: white;
        text-decoration: none;
      }

      .nav-links {
        display: flex;
        gap: 2rem;
      }

      .nav-links a {
        color: white;
        text-decoration: none;
        font-weight: 500;
        transition: opacity 0.2s;
      }

      .nav-links a:hover {
        opacity: 0.8;
      }

      /* Main Content */
      .main-content {
        max-width: 1200px;
        margin: 0 auto;
        padding: 0 2rem;
        display: grid;
        grid-template-columns: 1fr 300px;
        gap: 4rem;
      }

      .content-area {
        min-width: 0;
      }

      .sidebar {
        background: var(--bg-secondary);
        padding: 2rem;
        border-radius: 12px;
        height: fit-content;
        position: sticky;
        top: 2rem;
      }

      /* Enhanced Typography */
      h1, h2, h3, h4, h5, h6 {
        color: var(--text-color);
        font-weight: 700;
        line-height: 1.3;
        margin-top: 2.5rem;
        margin-bottom: 1rem;
      }

      h1 { font-size: 2.5rem; }
      h2 { font-size: 2rem; }
      h3 { font-size: 1.5rem; }

      /* Shortcode Styles */
      .alert {
        padding: 1rem 1.5rem;
        border-radius: 8px;
        margin: 1.5rem 0;
        display: flex;
        align-items: flex-start;
        gap: 0.75rem;
      }

      .alert-info { background: #ebf8ff; border-left: 4px solid #3182ce; }
      .alert-warning { background: #fffbeb; border-left: 4px solid #d69e2e; }
      .alert-error { background: #fed7d7; border-left: 4px solid #e53e3e; }
      .alert-success { background: #f0fff4; border-left: 4px solid #38a169; }

      .custom-quote {
        border-left: 4px solid var(--accent-color);
        padding: 1.5rem 2rem;
        margin: 2rem 0;
        background: var(--bg-secondary);
        border-radius: 0 8px 8px 0;
        font-size: 1.1em;
        font-style: italic;
      }

      .button {
        display: inline-block;
        padding: 0.75rem 1.5rem;
        border-radius: 6px;
        text-decoration: none;
        font-weight: 600;
        transition: all 0.2s;
        margin: 0.5rem 0.5rem 0.5rem 0;
      }

      .button-primary {
        background: var(--primary-color);
        color: white;
      }

      .button-primary:hover {
        background: var(--secondary-color);
        transform: translateY(-1px);
      }

      /* Responsive Design */
      @media (max-width: 768px) {
        .main-content {
          grid-template-columns: 1fr;
          gap: 2rem;
        }

        .site-nav {
          flex-direction: column;
          gap: 1rem;
          text-align: center;
        }

        .nav-links {
          gap: 1rem;
        }

        h1 { font-size: 2rem; }
        h2 { font-size: 1.5rem; }
      }
      CSS

      File.write("static/css/blog.css", blog_css)

      puts "Created blog template with enhanced features"
    end

    private def self.create_directories(dirs : Array(String))
      dirs.each { |dir| Dir.mkdir_p(dir) }
    end

    private def self.create_docs_template
      # Implementation for docs template would go here
      puts "Created documentation template"
    end

    private def self.create_portfolio_template
      # Implementation for portfolio template would go here
      puts "Created portfolio template"
    end

    private def self.create_minimal_template
      # Implementation for minimal template would go here
      puts "Created minimal template"
    end
  end
end