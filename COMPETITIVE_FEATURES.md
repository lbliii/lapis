# Lapis Competitive Features

Lapis now includes advanced features that make it competitive with modern static site generators like Next.js, Nuxt, Astro, and others. This document explains how to configure and use these features.

## 🚀 Incremental Builds

Lapis automatically tracks file changes and only rebuilds what's necessary, dramatically reducing build times.

### Configuration

```yaml
build:
  incremental: true      # Enable incremental builds
  parallel: true         # Enable parallel processing
  cache_dir: ".lapis-cache"  # Cache directory
  max_workers: 4         # Parallel workers (auto-detected)
  clean_build: false     # Force clean build
```

### Benefits

- **Faster rebuilds**: Only changed files are processed
- **Parallel processing**: Multiple files processed simultaneously
- **Smart caching**: File timestamps and dependencies tracked
- **Dependency analysis**: Changes propagate to dependent files

## 🔌 Plugin System

Extensible plugin architecture for third-party integrations and custom functionality.

### Built-in Plugins

#### SEO Plugin
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

#### Analytics Plugin
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

#### Asset Optimization Plugin
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

### Plugin Lifecycle Events

Plugins can hook into various build events:

- `BeforeBuild` - Before the build starts
- `AfterContentLoad` - After content is loaded
- `BeforePageRender` - Before each page is rendered
- `AfterPageRender` - After each page is rendered
- `AfterBuild` - After the build completes
- `BeforeAssetProcess` - Before asset processing
- `AfterAssetProcess` - After asset processing

### Creating Custom Plugins

```crystal
class MyPlugin < Lapis::Plugin
  def initialize(config : Hash(String, YAML::Any))
    super("my-plugin", "1.0.0", config)
  end

  def on_before_build(generator : Generator) : Nil
    log_info("My plugin is starting the build")
  end

  def on_after_page_render(generator : Generator, content : Content, rendered : String) : Nil
    # Modify rendered content
    enhanced = add_custom_functionality(rendered)
    # Note: This would need to be handled in the template system
  end

  # ... implement other required methods
end
```

## 📊 Performance Features

### Parallel Processing

Lapis uses Crystal's Fiber system for efficient parallel processing:

- **Content processing**: Multiple pages rendered simultaneously
- **Asset processing**: Images, CSS, and JS processed in parallel
- **File operations**: Concurrent file I/O operations

### Memory Management

Built-in memory profiling and optimization:

- **Memory monitoring**: Track heap usage during builds
- **Garbage collection**: Optimized GC settings for builds
- **Resource cleanup**: Automatic cleanup of temporary resources

### Benchmarking

Comprehensive performance monitoring:

- **Build phase timing**: Detailed timing for each build phase
- **Performance insights**: Identify bottlenecks and optimization opportunities
- **Resource usage**: Memory and CPU usage tracking

## 🎨 Asset Pipeline

Advanced asset processing with optimization:

### CSS Processing
- **Bundling**: Combine multiple CSS files
- **Minification**: Remove whitespace and optimize
- **Autoprefixing**: Add vendor prefixes automatically
- **PostCSS**: Advanced CSS transformations

### JavaScript Processing
- **Bundling**: Combine and optimize JS files
- **Minification**: Reduce file sizes
- **Tree shaking**: Remove unused code
- **Source maps**: Debug support

### Image Optimization
- **Format conversion**: Convert to modern formats (WebP, AVIF)
- **Responsive images**: Generate multiple sizes
- **Lazy loading**: Automatic lazy loading attributes
- **Compression**: Lossless and lossy optimization

### Configuration

```yaml
plugins:
  assets:
    enabled: true
    css:
      bundle: true
      minify: true
      autoprefix: true
    js:
      bundle: true
      minify: true
      tree_shake: true
    images:
      optimize: true
      generate_webp: true
      responsive: true
      lazy_load: true
```

## 🌐 Multi-Format Output

Generate content in multiple formats simultaneously:

### Supported Formats
- **HTML**: Traditional web pages
- **JSON**: API endpoints and structured data
- **RSS/Atom**: Syndication feeds
- **Markdown**: LLM-friendly format
- **XML**: Custom XML formats

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
```

### Template Usage

```html
<!-- Generate multiple formats -->
{{ content | render_formats: ["html", "json", "rss"] }}

<!-- Format-specific content -->
{% if format == "json" %}
  {{ content | to_json }}
{% elsif format == "rss" %}
  {{ content | to_rss }}
{% else %}
  {{ content }}
{% endif %}
```

## 🔍 SEO Features

Comprehensive SEO optimization:

### Automatic SEO
- **Meta tags**: Automatic generation of meta descriptions, keywords
- **Structured data**: JSON-LD schema markup
- **Open Graph**: Social media sharing optimization
- **Twitter Cards**: Twitter-specific meta tags

### Sitemap Generation
- **XML sitemaps**: Standard XML sitemap format
- **Image sitemaps**: Include images in sitemaps
- **News sitemaps**: Google News sitemap support
- **Multilingual sitemaps**: i18n sitemap support

### Configuration

```yaml
plugins:
  seo:
    enabled: true
    structured_data:
      organization:
        name: "My Company"
        url: "https://example.com"
        logo: "https://example.com/logo.png"
    social_cards:
      twitter:
        site: "@mysite"
        creator: "@mycreator"
      facebook:
        app_id: "your-facebook-app-id"
```

## 🌍 Internationalization (i18n)

Multi-language site support:

### Configuration

```yaml
plugins:
  i18n:
    enabled: true
    default_language: "en"
    languages:
      - code: "en"
        name: "English"
        path: "/"
      - code: "es"
        name: "Español"
        path: "/es"
      - code: "fr"
        name: "Français"
        path: "/fr"
```

### Template Usage

```html
<!-- Language-specific content -->
{% if lang == "en" %}
  <h1>Welcome</h1>
{% elsif lang == "es" %}
  <h1>Bienvenido</h1>
{% elsif lang == "fr" %}
  <h1>Bienvenue</h1>
{% endif %}

<!-- Language switcher -->
{% for language in site.languages %}
  <a href="{{ language.path }}">{{ language.name }}</a>
{% endfor %}
```

## 🚀 Edge Deployment

Deploy to modern edge platforms:

### Supported Platforms
- **Vercel**: Zero-config deployment
- **Netlify**: Git-based deployment
- **Cloudflare Pages**: Edge-optimized hosting
- **AWS Amplify**: AWS integration

### Configuration

```yaml
plugins:
  edge:
    enabled: true
    provider: "vercel"
    config:
      vercel_token: "your-vercel-token"
      project_id: "your-project-id"
```

## 📈 Development Experience

### Live Reload
Enhanced development server with WebSocket-based live reload:

```yaml
live_reload:
  enabled: true
  websocket_path: "/ws"
  debounce_ms: 300
  ignore_patterns:
    - "*.tmp"
    - "*.log"
```

### Debugging
Comprehensive logging and debugging:

```yaml
debug: true
log_level: "debug"
log_file: "lapis.log"
```

## 🎯 Performance Comparison

Lapis now competes with modern SSGs:

| Feature | Lapis | Next.js | Astro | Nuxt |
|---------|-------|---------|-------|------|
| Incremental Builds | ✅ | ✅ | ✅ | ✅ |
| Plugin System | ✅ | ✅ | ✅ | ✅ |
| Asset Optimization | ✅ | ✅ | ✅ | ✅ |
| Multi-format Output | ✅ | ❌ | ❌ | ❌ |
| Parallel Processing | ✅ | ✅ | ✅ | ✅ |
| SEO Features | ✅ | ✅ | ✅ | ✅ |
| i18n Support | ✅ | ✅ | ✅ | ✅ |
| Edge Deployment | ✅ | ✅ | ✅ | ✅ |

## 🚀 Getting Started

1. **Install Lapis**:
   ```bash
   shards install
   crystal build src/lapis.cr -o bin/lapis
   ```

2. **Configure your site**:
   ```bash
   cp exampleSite/lapis.yml .
   # Edit lapis.yml with your configuration
   ```

3. **Build your site**:
   ```bash
   bin/lapis build
   ```

4. **Start development server**:
   ```bash
   bin/lapis serve
   ```

## 📚 Advanced Usage

### Custom Plugins

Create plugins in the `plugins/` directory:

```crystal
# plugins/my_plugin.cr
class MyPlugin < Lapis::Plugin
  def initialize(config : Hash(String, YAML::Any))
    super("my-plugin", "1.0.0", config)
  end

  def on_after_build(generator : Generator) : Nil
    # Custom build logic
    generate_custom_files(generator)
  end

  private def generate_custom_files(generator : Generator)
    # Implementation
  end
end
```

### Custom Output Formats

```yaml
output_formats:
  formats:
    pdf:
      extension: "pdf"
      mime_type: "application/pdf"
    epub:
      extension: "epub"
      mime_type: "application/epub+zip"
```

### Performance Tuning

```yaml
build:
  max_workers: 8  # Increase for powerful machines
  cache_dir: "/tmp/lapis-cache"  # Use fast storage
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.
