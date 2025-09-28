# Lapis

A lightning-fast static site generator built in Crystal with intelligent optimization and modern developer experience.

[![Crystal](https://img.shields.io/badge/crystal-1.0+-blue.svg)](https://crystal-lang.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.2.0-brightgreen.svg)](https://github.com/lapis-lang/lapis/releases)

## ⚡ Features

### 🚀 **Performance & Optimization**
- **Lightning Fast**: Crystal-powered builds in milliseconds
- **Smart Asset Processing**: Automatic image optimization with WebP conversion
- **Responsive Images**: Auto-generated srcsets for all screen sizes
- **Build Analytics**: Detailed performance insights and optimization hints
- **Incremental Processing**: Only rebuild what's changed

### 🎨 **Modern Developer Experience**
- **Smart Templates**: Pre-built templates for blogs, docs, and portfolios
- **Shortcodes**: Powerful content widgets (alerts, galleries, buttons)
- **Live Reload**: Instant browser updates during development
- **Performance Profiling**: Built-in build time analysis

### 📝 **Content Management**
- **Enhanced Markdown**: Full support with YAML frontmatter
- **RSS/Atom/JSON Feeds**: Automatic feed generation
- **Pagination**: Smart archive pagination with navigation
- **SEO Optimization**: Automated sitemaps and meta tags
- **Cross-References**: Intelligent content linking

### 🔧 **Developer Tools**
- **Interactive CLI**: Template galleries and guided setup
- **Hot Reload**: Instant updates without browser refresh
- **Asset Pipeline**: Automated CSS/JS optimization
- **Dark Mode**: Built-in theme switching

## 🚀 Quick Start

### Installation

Build from source (requires Crystal 1.0+):

```bash
git clone https://github.com/lapis-lang/lapis.git
cd lapis
shards install
crystal build src/lapis.cr --release -o bin/lapis
```

### Create Your First Site

```bash
# Quick start with default template
./bin/lapis init my-blog

# Or choose from professional templates
./bin/lapis init --template list
./bin/lapis init --template blog my-awesome-blog

# Enter the directory and start developing
cd my-blog
../bin/lapis serve
```

Visit `http://localhost:3000` to see your site!

### Template Gallery

```bash
# List available templates
lapis init --template list

# Available templates:
# blog        Personal Blog - Clean, responsive blog template
# docs        Documentation Site - Technical docs with sidebar navigation
# portfolio   Portfolio Site - Showcase your work professionally
# minimal     Minimal Site - Ultra-clean template focusing on content
```

### Enhanced Content Creation

```bash
# Create content with intelligent defaults
lapis new page "About"
lapis new post "My First Post"

# Use powerful shortcodes in your content
{% image "hero.jpg" "Beautiful landscape" %}
{% alert "info" %}This is an info alert{% endalert %}
{% button "https://example.com" "Call to Action" "primary" %}

# Build with performance analytics
lapis build
```

## 📁 Project Structure

```
my-blog/
├── config.yml          # Site configuration
├── content/             # Your content files
│   ├── index.md        # Homepage
│   ├── about.md        # Pages
│   └── posts/          # Blog posts
│       └── welcome.md
├── layouts/            # Custom layouts (optional)
├── static/             # Static assets
│   ├── css/
│   ├── js/
│   └── images/
└── public/             # Generated site (after build)
```

## 📝 Writing Content

Content is written in Markdown with YAML frontmatter:

```markdown
---
title: "My First Post"
date: "2024-01-15 10:00:00 UTC"
tags: ["hello", "world"]
categories: ["blog"]
layout: "post"
description: "My very first blog post"
---

# My First Post

This is my first post written in **Markdown**!

## Features I Love

- Easy to write
- Fast to build
- Beautiful output

```

### Frontmatter Fields

- `title`: Post/page title (required)
- `date`: Publication date in ISO format
- `tags`: Array of tags for organization
- `categories`: Content categories
- `layout`: Template to use (default: "post" for posts, "default" for pages)
- `description`: Meta description for SEO
- `author`: Author name
- `draft`: Set to `true` to exclude from builds
- `toc`: Enable table of contents generation

## ⚙️ Configuration

Configure your site in `config.yml`:

```yaml
title: "My Lapis Site"
baseurl: "https://mysite.com"
description: "A beautiful site built with Lapis"
author: "Your Name"

# Build settings
output_dir: "public"
permalink: "/:year/:month/:day/:title/"

# Server settings
port: 3000
host: "localhost"

# Markdown settings
markdown:
  syntax_highlighting: true
  toc: true
  smart_quotes: true
  footnotes: true
  tables: true
```

## 🎨 Themes and Customization

### Using the Default Theme

Lapis comes with a beautiful responsive theme that supports:

- Clean, readable typography
- Responsive design for all devices
- Dark mode support
- Syntax highlighting for code
- Tag and category organization

### Custom Layouts

Create custom layouts in the `layouts/` directory:

```html
<!-- layouts/custom.html -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>{{ title }} - {{ site.title }}</title>
</head>
<body>
  <h1>{{ title }}</h1>
  {{ content }}
</body>
</html>
```

Use in your content frontmatter:

```yaml
---
title: "Custom Page"
layout: "custom"
---
```

### Custom Styling

Add custom CSS in `static/css/custom.css` and reference it in your layouts.

## 🔧 CLI Commands

```bash
# Create sites with templates
lapis init <site-name>
lapis init --template <template> <site-name>
lapis init --template list

# Build with analytics
lapis build                    # Shows performance report

# Development server
lapis serve                    # Live reload + file watching

# Smart content creation
lapis new page <title>         # Creates optimized pages
lapis new post <title>         # Creates blog posts with metadata

# Get help
lapis help
```

## 🎨 **New in v0.2.0**

### **Smart Asset Processing**
- Automatic image optimization and WebP conversion
- Responsive image generation with multiple sizes
- Asset fingerprinting for cache busting
- CSS/JS minification and optimization

### **Powerful Shortcodes**
Transform your content with built-in widgets:

```markdown
<!-- Responsive images -->
{% image "screenshot.png" "App screenshot" %}

<!-- Alert boxes -->
{% alert "warning" %}Important notice!{% endalert %}

<!-- Interactive elements -->
{% button "https://example.com" "Get Started" "primary" %}

<!-- Content galleries -->
{% gallery "portfolio/projects" %}

<!-- Code blocks with copy -->
{% highlight "crystal" %}
puts "Hello, Lapis!"
{% endhighlight %}
```

### **Performance Analytics**
Get detailed insights into your build performance:

```
📊 Build Analytics Report
═══════════════════════════════════════
⏱️  Total Build Time: 1.23s
📝 Content Generated: 15 pages, 8 posts
🎨 Assets Processed: 24 images, 3 CSS files
💾 Total Output Size: 2.4MB

⚡ Performance Breakdown:
     Content Processing    456ms (37%)
     Asset Processing      321ms (26%)
     Feed Generation       89ms  (7%)

💡 Performance Insights:
     🚀 Excellent build performance! Under 2 seconds.
     📚 Consider implementing incremental builds for larger sites.
```

### **Professional Templates**
Choose from curated templates designed for different use cases:
- **Blog**: Personal writing with social features
- **Documentation**: Technical docs with navigation
- **Portfolio**: Creative showcase with galleries
- **Minimal**: Clean, content-focused design

## 🏗️ Development

### Building from Source

```bash
git clone https://github.com/lapis-lang/lapis.git
cd lapis
shards install
crystal build src/lapis.cr
```

### Running Tests

```bash
crystal spec
```

### Code Quality

```bash
# Run linter
shards run ameba

# Format code
crystal tool format
```

## 📚 Example Site

Explore the comprehensive example site in `exampleSite/`:

```bash
# View the example site
cd exampleSite
../bin/lapis serve
```

The example site showcases:
- All shortcode features with live examples
- Performance optimization in action
- Professional blog template
- SEO and analytics configuration
- Best practices and patterns

See `exampleSite/README.md` for detailed documentation.

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by [Hugo](https://gohugo.io/) for its speed and simplicity
- Inspired by [Sphinx](https://www.sphinx-doc.org/) for its documentation features
- Built with [Crystal](https://crystal-lang.org/) for performance and developer happiness

## 📞 Support

- **Documentation**: [GitHub Wiki](https://github.com/lapis-lang/lapis/wiki)
- **Issues**: [GitHub Issues](https://github.com/lapis-lang/lapis/issues)
- **Discussions**: [GitHub Discussions](https://github.com/lapis-lang/lapis/discussions)

---

Built with ❤️ using Crystal