---
title: "Developer Experience in Lapis: Live Reload, Hot Reload, and Modern Tooling"
date: "2024-01-30 16:45:00 UTC"
tags: ["developer-experience", "tooling", "live-reload", "hot-reload", "crystal"]
categories: ["development"]
layout: "post"
description: "Explore the modern developer experience features in Lapis including live reload, hot reload, performance monitoring, and development tooling"
author: "Lapis Team"
reading_time: 9
featured: true
series: "Developer Experience"
---

# Developer Experience in Lapis: Live Reload, Hot Reload, and Modern Tooling

A great developer experience is crucial for productivity and satisfaction. Lapis provides a modern, fast, and intuitive development environment that makes building static sites enjoyable and efficient.

## 🚀 Modern Development Workflow

### Quick Start
```bash
# Initialize a new site
lapis init my-site
cd my-site

# Start development server with live reload
lapis serve

# Build for production
lapis build
```

That's it! Your site is running at `http://localhost:3000` with live reload enabled.

## 🔄 Live Reload System

Lapis features a sophisticated live reload system that provides instant feedback during development.

### How It Works

1. **File Watching**: Monitors all content, layout, and asset files
2. **Change Detection**: Identifies what has changed and what needs rebuilding
3. **Selective Rebuild**: Only rebuilds affected pages and assets
4. **WebSocket Communication**: Pushes updates to the browser instantly
5. **Browser Refresh**: Automatically refreshes the page with new content

### Configuration
```yaml
# config.yml
live_reload:
  enabled: true
  websocket_path: "/ws"
  debounce_ms: 300
  ignore_patterns:
    - "*.tmp"
    - "*.log"
    - ".lapis-cache/**"
  watch_content: true
  watch_layouts: true
  watch_static: true
  watch_config: true
```

### Live Reload Features

- **Instant Updates**: Changes appear in the browser within milliseconds
- **Selective Reloading**: Only affected pages are rebuilt
- **Asset Watching**: CSS and JavaScript changes trigger immediate updates
- **Config Changes**: Configuration updates restart the server automatically
- **Error Handling**: Graceful error recovery with helpful error messages

## 🔥 Hot Reload for Assets

Hot reload provides even faster updates for CSS and JavaScript without full page refreshes.

### CSS Hot Reload
```css
/* Changes to CSS files are injected instantly */
.site-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 2rem 0;
}

.post-content {
  font-family: 'Georgia', serif;
  line-height: 1.7;
  max-width: 800px;
  margin: 0 auto;
}
```

### JavaScript Hot Reload
```javascript
// JavaScript changes are applied without page refresh
document.addEventListener('DOMContentLoaded', function() {
  // Interactive features
  const menuToggle = document.querySelector('.menu-toggle');
  const navigation = document.querySelector('.navigation');
  
  menuToggle.addEventListener('click', function() {
    navigation.classList.toggle('active');
  });
});
```

## 🛠️ Development Tools

### Built-in CLI Commands

#### Site Management
```bash
# Create new sites
lapis init <site-name>
lapis init --template <template> <site-name>
lapis init --template list

# Build and serve
lapis build
lapis serve
lapis serve --port 8080
```

#### Content Management
```bash
# Create new content
lapis new page "Page Title"
lapis new post "Post Title"
lapis new post "Post Title" --draft

# Content validation
lapis validate
lapis check-links
```

#### Performance Analysis
```bash
# Performance monitoring
lapis build --analytics
lapis build --profile
lapis benchmark

# Memory analysis
lapis build --memory-profile
```

### Interactive CLI

Lapis provides an interactive CLI for guided setup:

```bash
$ lapis init
? What would you like to name your site? my-awesome-site
? What type of site are you building?
  ❯ Blog
    Documentation
    Portfolio
    Corporate
    Custom
? Would you like to use a theme?
  ❯ Default theme
    Custom theme
    No theme
? Enable live reload? (Y/n) Y
? Enable analytics? (y/N) N
? Enable SEO optimization? (Y/n) Y

Creating site structure...
✅ Site created successfully!
✅ Dependencies installed
✅ Initial build completed

🚀 Your site is ready! Run 'lapis serve' to start developing.
```

## 📊 Performance Monitoring

### Real-time Build Analytics

Lapis provides detailed performance insights during development:

```
📊 Build Analytics Report
═══════════════════════════════════════
Build Time: 0.3s
Pages Generated: 45
Assets Processed: 23
Memory Peak: 45MB
Cache Hit Rate: 87%

Performance Score: A+ (98/100)

Optimization Suggestions:
✅ All images optimized
✅ CSS minified and bundled
✅ JavaScript tree-shaken
⚠️  Consider enabling WebP for remaining PNGs
```

### Development Server Metrics

Monitor development server performance in real-time:

```
🚀 Development Server Running
═══════════════════════════════════════
Server: http://localhost:3000
WebSocket: ws://localhost:3000/ws
Live Reload: ✅ Enabled
Hot Reload: ✅ Enabled

📊 Performance Metrics:
- Response Time: 12ms
- Memory Usage: 45MB
- CPU Usage: 8%
- Active Connections: 1

🔄 File Watching:
- Content Files: 23 watched
- Layout Files: 8 watched
- Static Assets: 15 watched
- Config Files: 2 watched
```

## 🎨 Template Development

### Template Hot Reload

Templates are automatically reloaded when changed:

```html
<!-- layouts/post.html -->
{{ extends "baseof" }}

{{ block "main" }}
<article class="post">
  <header class="post-header">
    <h1>{{ title }}</h1>
    <div class="post-meta">
      <time datetime="{{ date }}">{{ date_formatted }}</time>
      {{ if tags }}
      <div class="post-tags">
        {{ range tags }}
          <span class="tag">{{ . }}</span>
        {{ end }}
      </div>
      {{ end }}
    </div>
  </header>

  <div class="post-content">
    {{ content }}
  </div>
</article>
{{ endblock }}
```

### Template Debugging

Lapis provides helpful debugging information for templates:

```html
<!-- Debug template variables -->
{{ if debug }}
<div class="debug-info">
  <h3>Template Debug Info</h3>
  <pre>{{ page | tojson }}</pre>
  <pre>{{ site | tojson }}</pre>
</div>
{{ end }}
```

## 🔧 Asset Pipeline

### CSS Development

```css
/* static/css/main.css */
/* Import other CSS files */
@import 'reset.css';
@import 'base.css';
@import 'components.css';

/* Use modern CSS features */
.site-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 2rem 0;
  
  /* CSS Grid for layout */
  display: grid;
  grid-template-columns: 1fr auto;
  align-items: center;
  gap: 2rem;
}

/* Responsive design */
@media (max-width: 768px) {
  .site-header {
    grid-template-columns: 1fr;
    text-align: center;
  }
}
```

### JavaScript Development

```javascript
// static/js/main.js
// Modern JavaScript with ES6+ features
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

    // Close menu when clicking outside
    document.addEventListener('click', (e) => {
      if (!this.navigation.contains(e.target)) {
        this.closeMenu();
      }
    });
  }

  toggleMenu() {
    this.navigation.classList.toggle('active');
  }

  closeMenu() {
    this.navigation.classList.remove('active');
  }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  new SiteNavigation();
});
```

## 🐛 Error Handling and Debugging

### Compile-time Error Checking

Crystal provides excellent compile-time error checking:

```crystal
# Crystal catches errors at compile time
def process_content(content : String) : String
  content
    .gsub(/\n+/, "\n")           # ✅ Valid
    .gsub(/\s+/, " ")            # ✅ Valid
    .strip                       # ✅ Valid
    .upcase                      # ✅ Valid
    .downcase                    # ✅ Valid
    .capitalize                  # ✅ Valid
    .reverse                     # ✅ Valid
    .gsub(/pattern/, "replacement") # ✅ Valid
end
```

### Runtime Error Handling

```crystal
# Graceful error handling
def safe_process_content(content : String?) : String
  return "" if content.nil?
  
  begin
    process_content(content)
  rescue e : Exception
    Log.error("Error processing content: #{e.message}")
    content
  end
end
```

### Development Error Pages

Lapis provides helpful error pages during development:

```html
<!-- Error page template -->
<!DOCTYPE html>
<html>
<head>
  <title>Build Error - {{ site.title }}</title>
  <style>
    body { font-family: monospace; margin: 2rem; }
    .error { color: #e74c3c; }
    .warning { color: #f39c12; }
    .info { color: #3498db; }
    pre { background: #f8f9fa; padding: 1rem; border-radius: 4px; }
  </style>
</head>
<body>
  <h1 class="error">Build Error</h1>
  <p><strong>File:</strong> {{ error.file }}</p>
  <p><strong>Line:</strong> {{ error.line }}</p>
  <p><strong>Message:</strong> {{ error.message }}</p>
  
  <h2>Stack Trace</h2>
  <pre>{{ error.stack_trace }}</pre>
  
  <h2>Suggestions</h2>
  <ul>
    {{ range error.suggestions }}
      <li>{{ . }}</li>
    {{ end }}
  </ul>
</body>
</html>
```

## 📱 Mobile Development

### Responsive Design Testing

Lapis development server supports responsive design testing:

```bash
# Start server with mobile viewport
lapis serve --mobile

# Test different viewports
lapis serve --viewport 375x667  # iPhone
lapis serve --viewport 768x1024  # iPad
lapis serve --viewport 1920x1080 # Desktop
```

### Device Simulation

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

## 🔍 Content Validation

### Frontmatter Validation

Lapis validates frontmatter automatically:

```yaml
---
title: "My Post"           # ✅ Required field
date: "2024-01-30"         # ✅ Valid date format
tags: ["tag1", "tag2"]     # ✅ Array format
categories: ["cat1"]       # ✅ Array format
layout: "post"             # ✅ Valid layout
description: "Post desc"   # ✅ String format
author: "Author Name"       # ✅ String format
draft: false               # ✅ Boolean format
featured: true             # ✅ Boolean format
reading_time: 5            # ✅ Integer format
---
```

### Link Checking

```bash
# Check for broken links
lapis check-links

# Check external links
lapis check-links --external

# Check with specific timeout
lapis check-links --timeout 10
```

## 🚀 Production Deployment

### Build Optimization

```bash
# Production build with optimizations
lapis build --production

# Build with performance profiling
lapis build --profile

# Build with analytics
lapis build --analytics
```

### Deployment Commands

```bash
# Deploy to various platforms
lapis deploy netlify
lapis deploy vercel
lapis deploy github-pages
lapis deploy s3

# Custom deployment
lapis deploy --command "rsync -av public/ user@server:/var/www/"
```

## 🎯 Best Practices

### Development Workflow

1. **Use live reload**: Enable for instant feedback
2. **Enable hot reload**: For CSS/JS changes
3. **Monitor performance**: Use build analytics
4. **Validate content**: Check frontmatter and links
5. **Test responsive**: Use different viewports
6. **Debug templates**: Use debug information
7. **Optimize assets**: Minify and bundle for production

### Performance Tips

1. **Enable incremental builds**: Faster rebuilds
2. **Use parallel processing**: Leverage multiple cores
3. **Optimize images**: Use appropriate formats
4. **Minify assets**: Reduce file sizes
5. **Enable caching**: Use build cache
6. **Monitor memory**: Watch memory usage
7. **Profile builds**: Identify bottlenecks

### Error Prevention

1. **Use type safety**: Leverage Crystal's type system
2. **Validate input**: Check frontmatter and content
3. **Handle errors**: Graceful error recovery
4. **Test thoroughly**: Validate all functionality
5. **Monitor logs**: Watch for warnings and errors
6. **Use debug mode**: Enable debugging information
7. **Check links**: Validate all links work

## 🔮 Future Features

### Planned Enhancements

- **VS Code Extension**: Integrated development environment
- **Hot Module Replacement**: Even faster asset updates
- **TypeScript Support**: Enhanced JavaScript development
- **GraphQL Integration**: Dynamic content queries
- **Component System**: Reusable template components
- **Testing Framework**: Built-in testing tools
- **Performance Profiler**: Advanced performance analysis

{% alert "success" %}
**Modern Developer Experience**: Lapis provides a modern, fast, and intuitive development environment that makes building static sites enjoyable and productive. The combination of live reload, hot reload, and comprehensive tooling creates an exceptional developer experience.
{% endalert %}

---

*Ready to experience the modern developer experience of Lapis? [Get started today](https://github.com/lapis-lang/lapis) and see how enjoyable static site development can be.*
