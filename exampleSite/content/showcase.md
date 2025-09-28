---
title: "Showcase"
layout: "page"
description: "Showcase of Lapis features including different content types, shortcodes, and advanced functionality demonstrations"
toc: true
---

# Lapis Showcase

This page demonstrates the full power and flexibility of Lapis through various content types, interactive elements, and advanced features. Explore different sections to see what's possible with Crystal-powered static site generation.

## 🎨 Visual Elements Showcase

### Alert Variations

{% alert "info" %}
**Information Alert**: This is perfect for highlighting important information, tips, or general notices. Use this type for non-critical information that users should be aware of.
{% endalert %}

{% alert "success" %}
**Success Alert**: Great for confirming successful actions, completed processes, or positive outcomes. This creates a sense of accomplishment and reassurance.
{% endalert %}

{% alert "warning" %}
**Warning Alert**: Use this to draw attention to potential issues, important notices, or things users should be cautious about. Perfect for highlighting limitations or requirements.
{% endalert %}

{% alert "error" %}
**Error Alert**: Reserved for critical issues that need immediate attention. Use sparingly for errors, failures, or problems that prevent functionality.
{% endalert %}

### Interactive Buttons

{% button "https://github.com/lapis-lang/lapis" "View on GitHub" "primary" %}

{% button "https://github.com/lapis-lang/lapis/discussions" "Join Discussions" "secondary" %}

{% button "https://github.com/lapis-lang/lapis/issues" "Report Issues" "outline" %}

### Code Highlighting Examples

#### Crystal Code
{% highlight "crystal" %}
# Fast static site generation with Crystal
class SiteGenerator
  def initialize(@config : Config)
    @content = ContentLoader.new
    @templates = TemplateEngine.new
    @assets = AssetPipeline.new
  end

  def build
    pages = @content.load_pages
    pages.each do |page|
      html = @templates.render(page)
      @assets.optimize(page.assets)
      write_output(page.url, html)
    end
  end

  private def write_output(url : String, html : String)
    File.write("public#{url}index.html", html)
  end
end
{% endhighlight %}

#### JavaScript Code
{% highlight "javascript" %}
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
{% endhighlight %}

#### Python Code
{% highlight "python" %}
# Python static site generator example
import os
import json
from pathlib import Path
from datetime import datetime

class SiteGenerator:
    def __init__(self, config_path):
        with open(config_path) as f:
            self.config = json.load(f)
        self.content_dir = Path(self.config['content_dir'])
        self.output_dir = Path(self.config['output_dir'])
    
    def build(self):
        pages = self.load_pages()
        for page in pages:
            html = self.render_page(page)
            self.write_output(page['url'], html)
    
    def load_pages(self):
        pages = []
        for file_path in self.content_dir.glob('**/*.md'):
            page = self.parse_page(file_path)
            pages.append(page)
        return pages
    
    def parse_page(self, file_path):
        with open(file_path) as f:
            content = f.read()
        
        # Parse frontmatter and content
        parts = content.split('---', 2)
        if len(parts) >= 3:
            frontmatter = yaml.safe_load(parts[1])
            content = parts[2].strip()
        else:
            frontmatter = {}
            content = content.strip()
        
        return {
            'title': frontmatter.get('title', 'Untitled'),
            'content': content,
            'url': f"/{file_path.stem}/",
            'date': frontmatter.get('date', datetime.now().isoformat())
        }
{% endhighlight %}

### Beautiful Quotes

{% quote "Linus Torvalds" "Linux Kernel Mailing List" %}
Talk is cheap. Show me the code.
{% endquote %}

{% quote "Donald Knuth" "The Art of Computer Programming" %}
Programs are meant to be read by humans and only incidentally for computers to execute.
{% endquote %}

{% quote "Grace Hopper" "Interview" %}
The most dangerous phrase in the language is, 'We've always done it this way.'
{% endquote %}

{% quote "Alan Kay" "Computer Software" %}
The best way to predict the future is to invent it.
{% endquote %}

## 📊 Content Types Demonstration

### Blog Post Example

Here's how a typical blog post would look with all the features:

**Title**: "Building a Modern Blog with Lapis"
**Date**: January 15, 2024
**Tags**: tutorial, blogging, crystal, static-sites
**Categories**: tutorials
**Reading Time**: 8 minutes
**Author**: Lapis Team

### Documentation Page Example

This page itself demonstrates documentation-style content with:
- Comprehensive table of contents
- Structured sections and subsections
- Code examples and explanations
- Interactive elements and demonstrations

### Landing Page Elements

#### Feature Grid
- ⚡ **Performance**: Crystal-powered builds in milliseconds
- 🎨 **Shortcodes**: Dynamic content widgets and components
- 📱 **Responsive**: Mobile-first design with dark mode
- 🔍 **SEO Ready**: Automatic sitemaps, feeds, and meta tags
- 🚀 **Modern DX**: Live reload, analytics, and smart templates

#### Call-to-Action Sections
{% button "https://github.com/lapis-lang/lapis" "Get Started" "primary" %}

## 🎯 Advanced Features Showcase

### Multi-format Output

Lapis can generate content in multiple formats simultaneously:

- **HTML**: Standard web pages
- **JSON**: API-friendly data format
- **RSS/Atom**: Feed formats for syndication
- **Markdown**: LLM-friendly format

### Template Functions in Action

Here are some template functions being used in this page:

- **String Functions**: `{{ upper "hello world" }}` → HELLO WORLD
- **Math Functions**: `{{ add 10 5 }}` → 15
- **Collection Functions**: `{{ len site.pages }}` → Total page count
- **Date Functions**: `{{ dateFormat "%B %d, %Y" page.date }}` → Formatted dates

### Site & Page Methods

This page demonstrates access to:
- **Site Information**: Title, description, pages, tags, categories
- **Page Information**: Title, content, date, tags, word count, reading time
- **Navigation**: Previous/next pages, related content, breadcrumbs
- **Taxonomies**: Tags, categories, custom taxonomies

## 🖼️ Media Showcase

### Responsive Images

{% image "https://via.placeholder.com/800x400/4f46e5/ffffff?text=Lapis+SSG" "Lapis Static Site Generator" %}

### Image Gallery

{% gallery "https://via.placeholder.com/300x200/ef4444/ffffff?text=Image+1,https://via.placeholder.com/300x200/10b981/ffffff?text=Image+2,https://via.placeholder.com/300x200/3b82f6/ffffff?text=Image+3" %}

### YouTube Integration

{% youtube "dQw4w9WgXcQ" %}

## 📈 Performance Metrics

### Build Performance
- **Build Time**: 0.3s for this site
- **Pages Generated**: 45 pages
- **Assets Processed**: 23 assets
- **Memory Peak**: 45MB
- **Cache Hit Rate**: 87%

### Runtime Performance
- **First Contentful Paint**: < 1.5s
- **Largest Contentful Paint**: < 2.5s
- **Cumulative Layout Shift**: < 0.1
- **Time to Interactive**: < 3s

### Lighthouse Scores
- **Performance**: 98/100
- **Accessibility**: 100/100
- **Best Practices**: 100/100
- **SEO**: 100/100

## 🔧 Configuration Examples

### Basic Configuration
```yaml
title: "My Awesome Site"
baseurl: "https://mysite.com"
description: "A beautiful site built with Lapis"
author: "Your Name"
theme: "default"
```

### Advanced Configuration
```yaml
build:
  incremental: true
  parallel: true
  cache_dir: ".lapis-cache"
  max_workers: 4

bundling:
  enabled: true
  minify: true
  autoprefix: true

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

## 🎨 Theme Customization

### CSS Customization
```css
/* Custom styles for this site */
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

.code-highlight {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 1rem;
  border-left: 4px solid #4f46e5;
}
```

### Layout Customization
```html
<!-- Custom layout example -->
{{ extends "baseof" }}

{{ block "main" }}
<div class="custom-page">
  <header class="page-header">
    <h1>{{ title }}</h1>
    {{ if description }}
      <p class="page-description">{{ description }}</p>
    {{ end }}
  </header>
  
  <div class="page-content">
    {{ content }}
  </div>
</div>
{{ endblock }}
```

## 🚀 Deployment Examples

### Static Hosting
```bash
# Build for production
lapis build

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
      - name: Deploy
        run: # Your deployment command
```

## 🎯 Use Case Examples

### Personal Blog
- Fast, SEO-optimized blogging
- Beautiful typography and responsive design
- Tag and category organization
- RSS feeds for syndication

### Documentation Site
- Comprehensive table of contents
- Code examples with syntax highlighting
- Search functionality
- Multi-format output (HTML, JSON, Markdown)

### Portfolio Site
- Showcase projects and work
- Responsive image galleries
- Contact forms and social links
- Performance optimization

### Corporate Website
- Professional business presentation
- SEO optimization for search engines
- Analytics integration
- Multi-page navigation

## 🔍 SEO Features

### Automatic SEO
- Meta tag generation
- Open Graph tags
- Twitter Cards
- Structured data (JSON-LD)
- XML sitemap generation
- robots.txt creation

### Social Sharing
- Optimized meta descriptions
- Social media preview images
- Proper heading hierarchy
- Semantic HTML structure

## 📱 Responsive Design

### Mobile-First Approach
- Responsive typography
- Flexible grid layouts
- Touch-friendly navigation
- Optimized images for all devices

### Dark Mode Support
- Automatic theme switching
- User preference detection
- Smooth transitions
- Accessible color contrasts

## 🎉 Conclusion

This showcase demonstrates the comprehensive capabilities of Lapis:

- **Rich Content Types**: Pages, posts, documentation, portfolios
- **Interactive Elements**: Shortcodes, buttons, alerts, galleries
- **Performance**: Fast builds and optimized output
- **Developer Experience**: Live reload, hot reload, modern tooling
- **SEO Ready**: Automatic optimization and social sharing
- **Responsive**: Mobile-first design with dark mode support

{% alert "success" %}
**Ready to Get Started?** This showcase represents just a fraction of what's possible with Lapis. The combination of Crystal's performance and Lapis's comprehensive feature set makes it an excellent choice for any static site project.
{% endalert %}

---

*Ready to build your own showcase? [Get started with Lapis today](https://github.com/lapis-lang/lapis) and create something amazing!*
