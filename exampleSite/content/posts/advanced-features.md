---
title: "Advanced Lapis Features: Plugins, Custom Taxonomies, and Multi-format Output"
date: "2024-01-20 14:30:00 UTC"
tags: ["advanced", "plugins", "taxonomies", "crystal", "features"]
categories: ["advanced"]
layout: "post"
description: "Explore advanced Lapis features including plugin system, custom taxonomies, multi-format output, and performance optimization"
author: "Lapis Team"
reading_time: 12
featured: true
series: "Advanced Features"
---

# Advanced Lapis Features: Plugins, Custom Taxonomies, and Multi-format Output

Once you've mastered the basics of Lapis, it's time to explore the advanced features that make it a powerful platform for complex static sites. This guide covers plugins, custom taxonomies, multi-format output, and performance optimization techniques.

## 🔌 Plugin System

Lapis features a robust plugin system that allows you to extend functionality without modifying the core codebase.

### Built-in Plugins

#### SEO Plugin
The SEO plugin provides comprehensive search engine optimization features:

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

**Features:**
- Automatic meta tag generation
- Open Graph and Twitter Card support
- Structured data (JSON-LD) for rich snippets
- XML sitemap generation
- robots.txt creation

#### Analytics Plugin
Integrate multiple analytics providers:

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
      umami:
        url: "https://analytics.example.com"
        website_id: "your-website-id"
        enabled: false
```

#### Asset Optimization Plugin
Automatic asset optimization and bundling:

```yaml
plugins:
  assets:
    enabled: true
    minify_css: true
    minify_js: true
    optimize_images: true
    generate_webp: true
    bundle_css: true
    bundle_js: true
```

### Creating Custom Plugins

Create custom plugins to extend Lapis functionality:

```crystal
# plugins/custom_plugin.cr
class CustomPlugin < Lapis::Plugin
  def initialize(config : Hash(String, YAML::Any))
    super("custom-plugin", "1.0.0", config)
  end

  def on_after_build(generator : Generator) : Nil
    generate_custom_files(generator)
    optimize_content(generator)
  end

  private def generate_custom_files(generator : Generator)
    # Custom file generation logic
    custom_content = generate_custom_content(generator)
    write_file("custom-output.json", custom_content)
  end

  private def optimize_content(generator : Generator)
    # Content optimization logic
    generator.pages.each do |page|
      optimize_page_content(page)
    end
  end
end
```

### Plugin Lifecycle Events

Plugins can hook into various build events:

```crystal
class MyPlugin < Lapis::Plugin
  def on_before_build(generator : Generator) : Nil
    # Before build starts
    setup_custom_processing(generator)
  end

  def on_after_content_load(generator : Generator) : Nil
    # After content is loaded
    process_content(generator)
  end

  def on_before_page_render(page : Page) : Nil
    # Before each page is rendered
    preprocess_page(page)
  end

  def on_after_page_render(page : Page) : Nil
    # After each page is rendered
    postprocess_page(page)
  end

  def on_after_build(generator : Generator) : Nil
    # After build completes
    generate_reports(generator)
  end
end
```

## 🏷️ Custom Taxonomies

Organize your content with custom taxonomies beyond tags and categories.

### Defining Custom Taxonomies

```yaml
# config.yml
taxonomies:
  tags:
    weight: 1
  categories:
    weight: 2
  authors:
    weight: 3
  series:
    weight: 4
  technologies:
    weight: 5
  difficulty:
    weight: 6
```

### Using Custom Taxonomies

In your content frontmatter:

```yaml
---
title: "Advanced Crystal Programming"
tags: ["crystal", "programming", "advanced"]
categories: ["programming", "tutorials"]
authors: ["John Doe", "Jane Smith"]
series: "Crystal Mastery"
technologies: ["crystal", "web", "api"]
difficulty: "advanced"
---
```

### Template Usage

Access custom taxonomies in templates:

```html
<!-- Display authors -->
{{ if page.authors }}
<div class="authors">
  <h3>Authors</h3>
  {{ range page.authors }}
    <span class="author">{{ . }}</span>
  {{ end }}
</div>
{{ end }}

<!-- Display technologies -->
{{ if page.technologies }}
<div class="technologies">
  <h3>Technologies Used</h3>
  {{ range page.technologies }}
    <span class="tech-badge">{{ . }}</span>
  {{ end }}
</div>
{{ end }}

<!-- Difficulty indicator -->
{{ if page.difficulty }}
<div class="difficulty difficulty-{{ page.difficulty }}">
  <span>Difficulty: {{ title page.difficulty }}</span>
</div>
{{ end }}
```

### Taxonomy Pages

Generate taxonomy listing pages:

```html
<!-- layouts/taxonomy.html -->
{{ extends "baseof" }}

{{ block "main" }}
<div class="taxonomy-page">
  <h1>{{ title .title }}</h1>
  <p>{{ len .pages }} {{ .singular }} found</p>
  
  <div class="taxonomy-content">
    {{ range .pages }}
      <article class="taxonomy-item">
        <h2><a href="{{ .url }}">{{ .title }}</a></h2>
        <p>{{ .summary }}</p>
        <div class="meta">
          <time>{{ dateFormat "%B %d, %Y" .date }}</time>
          {{ if .reading_time }}
            <span>{{ .reading_time }} min read</span>
          {{ end }}
        </div>
      </article>
    {{ end }}
  </div>
</div>
{{ endblock }}
```

## 📊 Multi-format Output

Generate content in multiple formats simultaneously for different use cases.

### Configuration

```yaml
output_formats:
  default: "html"
  formats:
    html:
      extension: "html"
      mime_type: "text/html"
    json:
      extension: "json"
      mime_type: "application/json"
    rss:
      extension: "xml"
      mime_type: "application/rss+xml"
    atom:
      extension: "xml"
      mime_type: "application/atom+xml"
    llm:
      extension: "md"
      mime_type: "text/markdown"
```

### Content-specific Outputs

```yaml
# config.yml
outputs:
  single: ["html", "json", "llm"]
  home: ["html", "rss"]
  list: ["html", "rss"]
```

### Custom Output Templates

Create custom templates for different formats:

```html
<!-- layouts/single.json.json -->
{
  "title": "{{ page.title }}",
  "content": "{{ page.content | plainify }}",
  "date": "{{ page.date }}",
  "tags": {{ page.tags | tojson }},
  "categories": {{ page.categories | tojson }},
  "url": "{{ page.url }}",
  "reading_time": {{ page.reading_time }},
  "word_count": {{ page.word_count }}
}
```

```html
<!-- layouts/single.llm.txt -->
# {{ page.title }}

**Date:** {{ page.date }}
**Tags:** {{ page.tags | join ", " }}
**Reading Time:** {{ page.reading_time }} minutes

{{ page.content }}
```

## 🚀 Performance Optimization

### Advanced Build Configuration

```yaml
build:
  incremental: true
  parallel: true
  cache_dir: ".lapis-cache"
  max_workers: 8
  clean_build: false
  memory_limit: "1GB"
  timeout: 300
```

### Asset Pipeline Optimization

```yaml
bundling:
  enabled: true
  minify: true
  source_maps: false
  autoprefix: true
  tree_shake: true
  
  css_bundles:
    - name: "critical"
      files:
        - "static/css/critical.css"
      output: "assets/css/critical.min.css"
      order: 1
      
    - name: "main"
      files:
        - "static/css/reset.css"
        - "static/css/base.css"
        - "static/css/layout.css"
      output: "assets/css/main.min.css"
      order: 2
      
  js_bundles:
    - name: "main"
      files:
        - "static/js/utils.js"
        - "static/js/main.js"
      output: "assets/js/main.min.js"
      order: 1
      
    - name: "analytics"
      files:
        - "static/js/analytics/gtag.js"
        - "static/js/analytics/events.js"
      output: "assets/js/analytics.min.js"
      order: 2
```

### Performance Monitoring

```crystal
# Performance monitoring plugin
class PerformancePlugin < Plugin
  def on_after_build(generator : Generator)
    generate_performance_report(generator)
    analyze_bundle_sizes(generator)
    check_core_web_vitals(generator)
  end

  private def generate_performance_report(generator : Generator)
    report = {
      build_time: generator.build_time,
      pages_generated: generator.pages.size,
      assets_processed: generator.assets.size,
      memory_peak: generator.memory_peak,
      cache_hit_rate: generator.cache_hit_rate
    }
    
    write_json("performance-report.json", report)
  end
end
```

## 🔧 Advanced Template Functions

### Custom Template Functions

Create custom template functions for specific needs:

```crystal
# Custom template functions
module CustomTemplateFunctions
  def reading_time_emoji(word_count : Int32) : String
    case word_count
    when 0..500
      "⚡"
    when 501..1000
      "📖"
    when 1001..2000
      "📚"
    else
      "📖📚"
    end
  end

  def difficulty_badge(difficulty : String) : String
    case difficulty.downcase
    when "beginner"
      '<span class="badge badge-beginner">Beginner</span>'
    when "intermediate"
      '<span class="badge badge-intermediate">Intermediate</span>'
    when "advanced"
      '<span class="badge badge-advanced">Advanced</span>'
    else
      '<span class="badge badge-default">' + difficulty.title + '</span>'
    end
  end

  def series_navigation(series : String) : String
    # Generate series navigation
    series_posts = site.pages.select { |p| p.series == series }
    return "" if series_posts.empty?
    
    html = "<nav class='series-nav'><h3>#{series}</h3><ol>"
    series_posts.each do |post|
      active = post.url == page.url ? " class='active'" : ""
      html += "<li#{active}><a href='#{post.url}'>#{post.title}</a></li>"
    end
    html += "</ol></nav>"
    html
  end
end
```

### Template Usage

```html
<!-- Use custom functions in templates -->
<div class="post-meta">
  <span class="reading-time">
    {{ reading_time_emoji page.word_count }} {{ page.reading_time }} min read
  </span>
  {{ if page.difficulty }}
    {{ difficulty_badge page.difficulty }}
  {{ end }}
</div>

{{ if page.series }}
  {{ series_navigation page.series }}
{{ end }}
```

## 📱 Responsive Design Patterns

### Mobile-first CSS

```css
/* Mobile-first responsive design */
.post-content {
  font-size: 16px;
  line-height: 1.6;
  padding: 1rem;
}

@media (min-width: 768px) {
  .post-content {
    font-size: 18px;
    line-height: 1.7;
    padding: 2rem;
    max-width: 800px;
    margin: 0 auto;
  }
}

@media (min-width: 1024px) {
  .post-content {
    font-size: 20px;
    padding: 3rem;
  }
}
```

### Responsive Images

```html
<!-- Responsive image with multiple formats -->
<picture>
  <source media="(max-width: 640px)" 
          srcset="/assets/image-mobile.webp">
  <source media="(max-width: 1024px)" 
          srcset="/assets/image-tablet.webp">
  <source srcset="/assets/image-desktop.webp">
  <img src="/assets/image-desktop.jpg"
       alt="Description"
       loading="lazy">
</picture>
```

## 🔍 Advanced SEO Features

### Structured Data

```html
<!-- layouts/partials/structured-data.html -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "{{ page.title }}",
  "description": "{{ page.description }}",
  "author": {
    "@type": "Person",
    "name": "{{ page.author }}"
  },
  "datePublished": "{{ page.date }}",
  "dateModified": "{{ page.lastmod }}",
  "publisher": {
    "@type": "Organization",
    "name": "{{ site.title }}",
    "logo": {
      "@type": "ImageObject",
      "url": "{{ site.baseurl }}/logo.png"
    }
  }
}
</script>
```

### Advanced Meta Tags

```html
<!-- layouts/partials/advanced-meta.html -->
<meta name="article:author" content="{{ page.author }}">
<meta name="article:published_time" content="{{ page.date }}">
<meta name="article:modified_time" content="{{ page.lastmod }}">
<meta name="article:section" content="{{ page.categories | first }}">
<meta name="article:tag" content="{{ page.tags | join "," }}">

<!-- Open Graph -->
<meta property="og:type" content="article">
<meta property="og:title" content="{{ page.title }}">
<meta property="og:description" content="{{ page.description }}">
<meta property="og:url" content="{{ page.url }}">
<meta property="og:image" content="{{ page.image | default site.image }}">

<!-- Twitter Cards -->
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="{{ page.title }}">
<meta name="twitter:description" content="{{ page.description }}">
<meta name="twitter:image" content="{{ page.image | default site.image }}">
```

## 🎯 Best Practices

### Performance
1. **Enable incremental builds** for faster development
2. **Use parallel processing** for large sites
3. **Optimize assets** with minification and bundling
4. **Implement lazy loading** for images and videos
5. **Use appropriate image formats** (WebP for modern browsers)

### SEO
1. **Generate structured data** for rich snippets
2. **Optimize meta tags** for social sharing
3. **Create XML sitemaps** for search engines
4. **Use semantic HTML** for better accessibility
5. **Implement breadcrumbs** for navigation

### Content Organization
1. **Use custom taxonomies** for better organization
2. **Create content series** for related posts
3. **Implement cross-references** between content
4. **Use consistent frontmatter** across content
5. **Optimize for readability** with proper formatting

## 🚀 Deployment Strategies

### Static Hosting
```bash
# Build for production
lapis build --production

# Deploy to various platforms
netlify deploy --prod --dir=public
vercel --prod
aws s3 sync public/ s3://your-bucket --delete
```

### CI/CD Pipeline
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
      - name: Deploy to production
        run: # Your deployment command
```

{% alert "success" %}
**Advanced Features Unlocked!** You now have access to the full power of Lapis. These advanced features enable you to build sophisticated static sites that rival dynamic applications in functionality while maintaining the performance benefits of static generation.
{% endalert %}

---

*Ready to explore these advanced features? [Check out the Lapis documentation](https://github.com/lapis-lang/lapis) for more examples and join the community to share your creations.*
