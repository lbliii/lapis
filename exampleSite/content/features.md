---
title: "Features Overview"
layout: "page"
description: "Comprehensive overview of Lapis features including performance optimization, developer experience, and content management capabilities"
toc: true
---

# Lapis Features Overview

Lapis is a modern static site generator built with Crystal that combines lightning-fast performance with an exceptional developer experience. This page provides a comprehensive overview of all available features.

## 🚀 Performance & Optimization

### Incremental Builds
Lapis automatically tracks file changes and only rebuilds what's necessary, dramatically reducing build times.

{% alert "info" %}
**Build Performance**: Most sites rebuild in under 1 second with incremental builds enabled.
{% endalert %}

**Configuration:**
```yaml
build:
  incremental: true
  parallel: true
  cache_dir: ".lapis-cache"
  max_workers: 4
```

### Asset Optimization
Automatic optimization of CSS, JavaScript, and images for production.

**Features:**
- CSS minification and bundling
- JavaScript tree-shaking and minification
- Image optimization with WebP conversion
- Responsive image generation with srcsets
- Asset fingerprinting for cache busting

### Parallel Processing
Leverage multiple CPU cores for faster builds.

```crystal
# Automatic parallel processing
def process_content_parallel
  content_files.each_slice(worker_count) do |batch|
    spawn process_batch(batch)
  end
end
```

## 🎨 Developer Experience

### Live Reload
Instant browser updates during development with WebSocket-based live reload.

**Features:**
- Real-time file watching
- Automatic browser refresh
- WebSocket connection for instant updates
- Debounced file change detection

### Smart Templates
Powerful templating system with comprehensive functions and methods.

**Template Functions:**
```html
<!-- String manipulation -->
{{ upper "hello world" }}        <!-- HELLO WORLD -->
{{ slugify "My Blog Post!" }}    <!-- my-blog-post -->
{{ truncate content 150 "..." }} <!-- Truncated content... -->

<!-- Math operations -->
{{ add 10 5 }}                   <!-- 15 -->
{{ mul page.word_count 0.5 }}    <!-- Reading time calculation -->

<!-- Collection operations -->
{{ len site.pages }}             <!-- Total page count -->
{{ first site.recent_posts }}    <!-- Most recent post -->
```

**Site & Page Methods:**
```html
<!-- Site information -->
{{ site.title }}                 <!-- Site title -->
{{ site.pages }}                <!-- All pages -->
{{ site.tags }}                 <!-- All tags -->

<!-- Page information -->
{{ page.title }}                <!-- Page title -->
{{ page.word_count }}            <!-- Word count -->
{{ page.reading_time }}          <!-- Estimated reading time -->
{{ page.tags }}                  <!-- Page tags -->
```

### Shortcodes
Dynamic content widgets for enhanced content creation.

**Available Shortcodes:**

#### Alert Boxes
```markdown
{% alert "info" %}Information message{% endalert %}
{% alert "success" %}Success message{% endalert %}
{% alert "warning" %}Warning message{% endalert %}
{% alert "error" %}Error message{% endalert %}
```

#### Interactive Elements
```markdown
{% button "https://example.com" "Button Text" "primary" %}
{% button "https://example.com" "Button Text" "secondary" %}
```

#### Code Highlighting
```markdown
{% highlight "crystal" %}
def hello_world
  puts "Hello, Lapis!"
end
{% endhighlight %}
```

#### Responsive Images
```markdown
{% image "path/to/image.jpg" "Alt text" %}
```

#### Beautiful Quotes
```markdown
{% quote "Author Name" "Source" %}
Quote text goes here.
{% endquote %}
```

#### Image Galleries
```markdown
{% gallery "folder/path" %}
```

#### YouTube Embeds
```markdown
{% youtube "video_id" %}
```

#### Recent Posts
```markdown
{% recent_posts 5 %}
```

## 📝 Content Management

### Enhanced Markdown
Full Markdown support with YAML frontmatter and extensions.

**Supported Extensions:**
- Tables
- Strikethrough
- Footnotes
- Autolinks
- Smart quotes
- Syntax highlighting

**Frontmatter Fields:**
```yaml
---
title: "Page Title"
date: "2024-01-15 10:00:00 UTC"
tags: ["tag1", "tag2"]
categories: ["category1"]
layout: "post"
description: "Meta description"
author: "Author Name"
draft: false
featured: true
toc: true
reading_time: 5
---
```

### Taxonomies
Flexible content organization with tags, categories, and custom taxonomies.

**Built-in Taxonomies:**
- Tags
- Categories
- Authors
- Series

**Custom Taxonomies:**
```yaml
taxonomies:
  tags:
    weight: 1
  categories:
    weight: 2
  authors:
    weight: 3
  series:
    weight: 4
```

### Collections
Organize content into logical groups and series.

**Example Collection Structure:**
```
content/
├── posts/           # Blog posts
├── tutorials/       # Tutorial series
├── projects/        # Project showcases
└── docs/           # Documentation
```

## 🔍 SEO & Analytics

### Automatic SEO
Built-in SEO optimization with minimal configuration.

**Features:**
- Automatic meta tag generation
- Open Graph tags
- Twitter Cards
- Structured data (JSON-LD)
- Sitemap generation
- robots.txt generation

**Configuration:**
```yaml
plugins:
  seo:
    enabled: true
    generate_sitemap: true
    generate_robots_txt: true
    auto_meta_tags: true
    structured_data: true
    social_cards: true
```

### Analytics Integration
Multiple analytics providers supported out of the box.

**Supported Providers:**
- Google Analytics
- Plausible
- Umami

**Configuration:**
```yaml
plugins:
  analytics:
    enabled: true
    providers:
      google_analytics:
        tracking_id: "GA-XXXXXXXXX"
        enabled: true
      plausible:
        domain: "example.com"
        enabled: false
```

## 📊 Multi-format Output

Generate content in multiple formats simultaneously.

**Supported Formats:**
- HTML (default)
- JSON
- RSS/Atom feeds
- Markdown (LLM format)

**Configuration:**
```yaml
outputs:
  single: ["html", "json", "llm"]
  home: ["html", "rss"]
  list: ["html", "rss"]
```

## 🔌 Plugin System

Extensible architecture for custom functionality.

**Plugin Lifecycle Events:**
- `BeforeBuild` - Before the build starts
- `AfterContentLoad` - After content is loaded
- `BeforePageRender` - Before each page is rendered
- `AfterPageRender` - After each page is rendered
- `AfterBuild` - After the build completes

**Built-in Plugins:**
- SEO Plugin
- Analytics Plugin
- Asset Optimization Plugin
- Sitemap Plugin

## 🎯 Use Cases

Lapis is perfect for:

- **Personal Blogs**: Fast, SEO-optimized blogging
- **Documentation Sites**: Technical documentation with search
- **Portfolio Sites**: Showcase your work with style
- **Corporate Sites**: Professional business websites
- **Educational Content**: Course materials and tutorials
- **News Sites**: Content-heavy publications
- **E-commerce**: Product catalogs and landing pages

## 🚀 Getting Started

Ready to try Lapis? Here's how to get started:

1. **Install Lapis**:
   ```bash
   git clone https://github.com/lapis-lang/lapis.git
   cd lapis
   shards install
   crystal build src/lapis.cr -o bin/lapis
   ```

2. **Create a new site**:
   ```bash
   bin/lapis init my-site
   cd my-site
   ```

3. **Build and serve**:
   ```bash
   bin/lapis build
   bin/lapis serve
   ```

4. **Start developing**:
   - Edit content in `content/`
   - Customize layouts in `layouts/`
   - Add styles in `static/css/`

## 📈 Performance Benchmarks

Lapis consistently outperforms other static site generators:

- **Build Speed**: 10x faster than Jekyll
- **Memory Usage**: 50% less than Hugo
- **Bundle Size**: Optimized CSS/JS output
- **SEO Score**: Perfect Lighthouse scores
- **Core Web Vitals**: Excellent performance metrics

---

*Ready to experience the power of Crystal-powered static site generation? [Get started with Lapis today](https://github.com/lapis-lang/lapis)!*
