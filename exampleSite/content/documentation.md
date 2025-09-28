---
title: "Documentation"
layout: "page"
description: "Comprehensive documentation for Lapis static site generator including installation, configuration, and advanced features"
toc: true
---

# Lapis Documentation

Welcome to the comprehensive documentation for Lapis, the Crystal-powered static site generator. This guide covers everything from basic installation to advanced features and customization.

## 📚 Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Content Management](#content-management)
- [Templates & Themes](#templates--themes)
- [Shortcodes](#shortcodes)
- [Asset Pipeline](#asset-pipeline)
- [Performance](#performance)
- [Deployment](#deployment)
- [API Reference](#api-reference)

## 🚀 Installation

### Prerequisites

- **Crystal 1.0+**: Required for building Lapis
- **Git**: For cloning the repository
- **Make**: For build automation (optional)

### Building from Source

```bash
# Clone the repository
git clone https://github.com/lapis-lang/lapis.git
cd lapis

# Install dependencies
shards install

# Build Lapis
crystal build src/lapis.cr -o bin/lapis

# Verify installation
./bin/lapis --version
```

### Alternative Installation Methods

#### Using Make
```bash
# Install dependencies and build
make install

# Build optimized binary
make build

# Run tests
make test
```

#### Using Docker
```bash
# Build Docker image
docker build -t lapis .

# Run Lapis in container
docker run -v $(pwd):/site lapis build
```

## 🎯 Quick Start

### Create Your First Site

```bash
# Initialize a new site
lapis init my-awesome-site
cd my-awesome-site

# Start development server
lapis serve
```

Visit `http://localhost:3000` to see your site!

### Basic Site Structure

```
my-awesome-site/
├── config.yml          # Site configuration
├── content/            # Your content files
│   ├── index.md       # Homepage
│   ├── about.md       # About page
│   └── posts/         # Blog posts
│       ├── _index.md  # Posts listing
│       └── welcome.md # First post
├── layouts/           # Custom layouts (optional)
├── static/            # Static assets
│   ├── css/
│   ├── js/
│   └── images/
└── public/            # Generated site
```

## ⚙️ Configuration

### Basic Configuration

```yaml
# config.yml
title: "My Awesome Site"
baseurl: "https://mysite.com"
description: "A beautiful site built with Lapis"
author: "Your Name"
theme: "default"

# Build settings
output_dir: "public"
permalink: "/:year/:month/:day/:title/"

# Server settings
port: 3000
host: "localhost"
```

### Advanced Configuration

```yaml
# Advanced configuration options
build:
  incremental: true
  parallel: true
  cache_dir: ".lapis-cache"
  max_workers: 4

bundling:
  enabled: true
  minify: true
  autoprefix: true

live_reload:
  enabled: true
  websocket_path: "/ws"
  debounce_ms: 300

plugins:
  seo:
    enabled: true
    generate_sitemap: true
    auto_meta_tags: true
  
  analytics:
    enabled: true
    providers:
      google_analytics:
        tracking_id: "GA-XXXXXXXXX"
```

## 📝 Content Management

### Writing Content

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

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | String | Yes | Post/page title |
| `date` | String | No | Publication date (ISO format) |
| `tags` | Array | No | Tags for organization |
| `categories` | Array | No | Content categories |
| `layout` | String | No | Template to use |
| `description` | String | No | Meta description |
| `author` | String | No | Author name |
| `draft` | Boolean | No | Hide from builds |
| `featured` | Boolean | No | Mark as featured |
| `toc` | Boolean | No | Enable table of contents |

### Content Types

#### Pages
Static content like About, Contact, etc.

```markdown
---
title: "About"
layout: "page"
---

# About Us

We are a team of passionate developers...
```

#### Posts
Blog articles with dates and metadata.

```markdown
---
title: "Getting Started with Lapis"
date: "2024-01-15"
tags: ["tutorial", "lapis"]
layout: "post"
---

# Getting Started with Lapis

Learn how to build fast static sites...
```

#### Collections
Organized content groups.

```markdown
---
title: "Tutorial Series"
layout: "collection"
---

# Tutorial Series

A collection of tutorials covering...
```

## 🎨 Templates & Themes

### Template System

Lapis uses a powerful template system based on Crystal's template engine:

```html
<!-- layouts/post.html -->
{{ extends "baseof" }}

{{ block "main" }}
<article class="post">
  <header>
    <h1>{{ title }}</h1>
    <div class="meta">
      <time>{{ date }}</time>
      {{ if tags }}
        <div class="tags">
          {{ range tags }}
            <span class="tag">{{ . }}</span>
          {{ end }}
        </div>
      {{ end }}
    </div>
  </header>
  
  <div class="content">
    {{ content }}
  </div>
</article>
{{ endblock }}
```

### Template Functions

Lapis provides comprehensive template functions:

#### String Functions
```html
{{ upper "hello world" }}        <!-- HELLO WORLD -->
{{ lower "SHOUT TEXT" }}        <!-- shout text -->
{{ title "article title" }}     <!-- Article Title -->
{{ slugify "My Blog Post!" }}   <!-- my-blog-post -->
{{ truncate content 150 "..." }} <!-- Truncated content... -->
```

#### Math Functions
```html
{{ add 10 5 }}                  <!-- 15 -->
{{ sub 20 8 }}                  <!-- 12 -->
{{ mul 6 7 }}                   <!-- 42 -->
{{ div 100 4 }}                 <!-- 25 -->
{{ min 3 7 }}                   <!-- 3 -->
{{ max 3 7 }}                   <!-- 7 -->
```

#### Collection Functions
```html
{{ len site.pages }}            <!-- Total page count -->
{{ first site.recent_posts }}   <!-- Most recent post -->
{{ last site.recent_posts }}     <!-- Oldest post -->
{{ sort site.tags }}            <!-- Sorted tags -->
{{ reverse site.posts }}        <!-- Reversed posts -->
```

### Site & Page Methods

Access comprehensive site and page information:

```html
<!-- Site information -->
{{ site.title }}                <!-- Site title -->
{{ site.description }}           <!-- Site description -->
{{ site.pages }}                <!-- All pages -->
{{ site.tags }}                 <!-- All tags -->
{{ site.categories }}           <!-- All categories -->

<!-- Page information -->
{{ page.title }}                <!-- Page title -->
{{ page.content }}              <!-- Page content -->
{{ page.date }}                 <!-- Publication date -->
{{ page.tags }}                 <!-- Page tags -->
{{ page.categories }}          <!-- Page categories -->
{{ page.word_count }}           <!-- Word count -->
{{ page.reading_time }}         <!-- Reading time -->
```

## 🎨 Shortcodes

Shortcodes provide dynamic content widgets:

### Alert Boxes
```markdown
{% alert "info" %}Information message{% endalert %}
{% alert "success" %}Success message{% endalert %}
{% alert "warning" %}Warning message{% endalert %}
{% alert "error" %}Error message{% endalert %}
```

### Interactive Elements
```markdown
{% button "https://example.com" "Button Text" "primary" %}
{% button "https://example.com" "Button Text" "secondary" %}
```

### Code Highlighting
```markdown
{% highlight "crystal" %}
def hello_world
  puts "Hello, Lapis!"
end
{% endhighlight %}
```

### Responsive Images
```markdown
{% image "path/to/image.jpg" "Alt text" %}
```

### Beautiful Quotes
```markdown
{% quote "Author Name" "Source" %}
Quote text goes here.
{% endquote %}
```

### Image Galleries
```markdown
{% gallery "folder/path" %}
```

### YouTube Embeds
```markdown
{% youtube "video_id" %}
```

### Recent Posts
```markdown
{% recent_posts 5 %}
```

### Table of Contents
```markdown
{% toc %}
```

## 📦 Asset Pipeline

### CSS Processing

```css
/* static/css/main.css */
@import 'reset.css';
@import 'base.css';
@import 'components.css';

.site-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 2rem 0;
}

@media (max-width: 768px) {
  .site-header {
    padding: 1rem 0;
  }
}
```

### JavaScript Processing

```javascript
// static/js/main.js
class SiteNavigation {
  constructor() {
    this.menuToggle = document.querySelector('.menu-toggle');
    this.navigation = document.querySelector('.navigation');
    this.init();
  }

  init() {
    this.menuToggle.addEventListener('click', () => {
      this.toggleMenu();
    });
  }

  toggleMenu() {
    this.navigation.classList.toggle('active');
  }
}

document.addEventListener('DOMContentLoaded', () => {
  new SiteNavigation();
});
```

### Asset Configuration

```yaml
bundling:
  enabled: true
  minify: true
  autoprefix: true
  
  css_bundles:
    - name: "main"
      files:
        - "static/css/reset.css"
        - "static/css/base.css"
        - "static/css/layout.css"
      output: "assets/css/main.min.css"
      
  js_bundles:
    - name: "main"
      files:
        - "static/js/utils.js"
        - "static/js/main.js"
      output: "assets/js/main.min.js"
```

## ⚡ Performance

### Build Performance

```yaml
build:
  incremental: true      # Enable incremental builds
  parallel: true         # Enable parallel processing
  cache_dir: ".lapis-cache"
  max_workers: 4         # Number of workers
```

### Asset Optimization

```yaml
plugins:
  assets:
    enabled: true
    minify_css: true
    minify_js: true
    optimize_images: true
    generate_webp: true
```

### Performance Monitoring

```bash
# Build with analytics
lapis build --analytics

# Performance profiling
lapis build --profile

# Memory analysis
lapis build --memory-profile
```

## 🚀 Deployment

### Static Hosting

Deploy to any static hosting service:

```bash
# Build for production
lapis build

# Deploy to Netlify
netlify deploy --prod --dir=public

# Deploy to Vercel
vercel --prod

# Deploy to GitHub Pages
git add public/
git commit -m "Deploy site"
git push origin gh-pages
```

### CI/CD Integration

```yaml
# .github/workflows/deploy.yml
name: Deploy Site
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Crystal
        uses: oprypin/crystal-setup-action@v1
      - name: Install dependencies
        run: shards install
      - name: Build site
        run: crystal build src/lapis.cr -o bin/lapis && bin/lapis build
      - name: Deploy
        run: # Your deployment command
```

## 📖 API Reference

### CLI Commands

#### Site Management
```bash
lapis init <site-name>              # Create new site
lapis init --template <template>    # Create with template
lapis init --template list         # List available templates
```

#### Build Commands
```bash
lapis build                        # Build site
lapis build --production          # Production build
lapis build --analytics           # Build with analytics
lapis build --profile             # Build with profiling
```

#### Development
```bash
lapis serve                       # Start development server
lapis serve --port 8080           # Custom port
lapis serve --host 0.0.0.0        # Custom host
```

#### Content Management
```bash
lapis new page "Title"            # Create new page
lapis new post "Title"            # Create new post
lapis new post "Title" --draft   # Create draft post
```

#### Validation
```bash
lapis validate                    # Validate content
lapis check-links                 # Check for broken links
lapis check-links --external      # Check external links
```

### Configuration Options

#### Build Configuration
```yaml
build:
  incremental: true                # Enable incremental builds
  parallel: true                  # Enable parallel processing
  cache_dir: ".lapis-cache"       # Cache directory
  max_workers: 4                  # Number of workers
  clean_build: false              # Force clean build
  memory_limit: "1GB"             # Memory limit
  timeout: 300                    # Build timeout
```

#### Asset Configuration
```yaml
bundling:
  enabled: true                   # Enable asset bundling
  minify: true                   # Minify assets
  source_maps: false             # Generate source maps
  autoprefix: true               # Add vendor prefixes
  tree_shake: true               # Remove unused code
```

#### Live Reload Configuration
```yaml
live_reload:
  enabled: true                   # Enable live reload
  websocket_path: "/ws"           # WebSocket path
  debounce_ms: 300                # Debounce time
  ignore_patterns:                # Ignore patterns
    - "*.tmp"
    - "*.log"
    - ".lapis-cache/**"
  watch_content: true             # Watch content files
  watch_layouts: true             # Watch layout files
  watch_static: true              # Watch static files
  watch_config: true              # Watch config files
```

#### Plugin Configuration
```yaml
plugins:
  seo:
    enabled: true                 # Enable SEO plugin
    generate_sitemap: true        # Generate sitemap
    generate_robots_txt: true     # Generate robots.txt
    auto_meta_tags: true          # Auto meta tags
    structured_data: true          # Structured data
    social_cards: true            # Social cards
  
  analytics:
    enabled: true                 # Enable analytics
    providers:
      google_analytics:
        tracking_id: "GA-XXXXXXXXX"
        enabled: true
      plausible:
        domain: "example.com"
        enabled: false
```

## 🎯 Best Practices

### Performance
1. **Enable incremental builds** for faster development
2. **Use parallel processing** for large sites
3. **Optimize assets** with minification and bundling
4. **Implement lazy loading** for images
5. **Use appropriate image formats** (WebP for modern browsers)

### SEO
1. **Generate structured data** for rich snippets
2. **Optimize meta tags** for social sharing
3. **Create XML sitemaps** for search engines
4. **Use semantic HTML** for better accessibility
5. **Implement breadcrumbs** for navigation

### Content Organization
1. **Use consistent frontmatter** across content
2. **Organize with taxonomies** (tags, categories)
3. **Create content series** for related posts
4. **Implement cross-references** between content
5. **Optimize for readability** with proper formatting

### Development
1. **Use live reload** for instant feedback
2. **Enable hot reload** for CSS/JS changes
3. **Monitor performance** with build analytics
4. **Validate content** regularly
5. **Test responsive design** on different devices

## 🆘 Troubleshooting

### Common Issues

#### Build Errors
```bash
# Check for syntax errors
lapis build --verbose

# Clean build cache
rm -rf .lapis-cache
lapis build
```

#### Performance Issues
```bash
# Profile build performance
lapis build --profile

# Check memory usage
lapis build --memory-profile
```

#### Content Issues
```bash
# Validate content
lapis build --validate

# Check for broken links
lapis check-links
```

### Getting Help

- **Documentation**: Comprehensive guides and API reference
- **GitHub Issues**: Bug reports and feature requests
- **Discussions**: Community discussions and Q&A
- **Discord**: Real-time community chat

---

*This documentation covers the core features of Lapis. For more advanced topics, check out our [Advanced Features Guide](/advanced-features) and [Performance Optimization Guide](/performance).*
