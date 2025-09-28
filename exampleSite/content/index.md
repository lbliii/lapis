---
title: "Lapis SSG"
layout: "home"
description: "The official example site showcasing Crystal-powered static site generation with comprehensive feature demonstrations"
featured: true
---

# Welcome to Lapis! ⚡

This is the **official example site** for Lapis, demonstrating the power and flexibility of Crystal-based static site generation. Explore the features, see the code, and get inspired!

{% recent_posts 6 %}

## 🚀 Core Features Showcased

### **Performance & Optimization**
- ⚡ **Lightning Fast**: Crystal-powered builds in milliseconds
- 🔄 **Incremental Builds**: Only rebuild what's changed
- 📦 **Asset Optimization**: Automatic CSS/JS minification and bundling
- 🖼️ **Smart Images**: WebP conversion and responsive srcsets
- 📊 **Build Analytics**: Detailed performance insights

### **Developer Experience**
- 🎨 **Shortcodes**: Dynamic content widgets and components
- 🔄 **Live Reload**: Instant browser updates during development
- 📱 **Responsive**: Mobile-first design with dark mode support
- 🔍 **SEO Ready**: Automatic sitemaps, feeds, and meta tags
- 🛠️ **Modern DX**: Hot reload, analytics, and smart templates

## 🎨 Shortcodes Demo

### Alert Boxes
{% alert "info" %}This is an info alert showcasing the alert shortcode! Perfect for highlighting important information.{% endalert %}

{% alert "success" %}Build completed successfully with excellent performance! All assets optimized and ready for production.{% endalert %}

{% alert "warning" %}This is a warning alert. Use it to draw attention to potential issues or important notices.{% endalert %}

{% alert "error" %}This is an error alert. Use sparingly for critical issues that need immediate attention.{% endalert %}

### Interactive Elements
{% button "https://github.com/lapis-lang/lapis" "View on GitHub" "primary" %}

{% button "https://github.com/lapis-lang/lapis/discussions" "Join Discussions" "secondary" %}

### Code Highlighting
{% highlight "crystal" %}
# Fast static site generation with Crystal
def build_site
  content = load_markdown_files
  html = process_templates(content)
  write_optimized_output(html)
end

# Performance optimization
def optimize_assets
  minify_css
  bundle_javascript
  convert_images_to_webp
end
{% endhighlight %}

### Beautiful Quotes
{% quote "Linus Torvalds" "Linux Kernel Mailing List" %}
Talk is cheap. Show me the code.
{% endquote %}

{% quote "Donald Knuth" "The Art of Computer Programming" %}
Programs are meant to be read by humans and only incidentally for computers to execute.
{% endquote %}

## 📚 Content Types

This example site demonstrates various content types and organizational strategies:

- **📄 Pages**: Static content like About, Documentation
- **📝 Posts**: Blog articles with dates, tags, and categories  
- **🏷️ Taxonomies**: Tags, categories, authors, and custom taxonomies
- **📊 Collections**: Organized content groups and series
- **🔗 Cross-references**: Intelligent content linking

## 🛠️ Technical Features

### Template Functions
Lapis provides powerful template functions for string manipulation, math operations, and content processing:

```html
<!-- String functions -->
{{ upper "hello world" }}        <!-- HELLO WORLD -->
{{ slugify "My Blog Post!" }}    <!-- my-blog-post -->
{{ truncate content 150 "..." }} <!-- Truncated content... -->

<!-- Math functions -->
{{ add 10 5 }}                   <!-- 15 -->
{{ mul page.word_count 0.5 }}    <!-- Reading time calculation -->

<!-- Collection functions -->
{{ len site.pages }}             <!-- Total page count -->
{{ first site.recent_posts }}    <!-- Most recent post -->
```

### Site & Page Methods
Access comprehensive site and page information:

```html
<!-- Site information -->
{{ site.title }}                 <!-- Site title -->
{{ len site.pages }}             <!-- Total pages -->
{{ site.tags }}                 <!-- All tags -->

<!-- Page information -->
{{ page.title }}                <!-- Page title -->
{{ page.word_count }}            <!-- Word count -->
{{ page.reading_time }}          <!-- Estimated reading time -->
{{ page.tags }}                  <!-- Page tags -->
```

## 🎯 Use Cases

Lapis is perfect for:

- **📝 Personal Blogs**: Fast, SEO-optimized blogging
- **📚 Documentation Sites**: Technical documentation with search
- **💼 Portfolio Sites**: Showcase your work with style
- **🏢 Corporate Sites**: Professional business websites
- **🎓 Educational Content**: Course materials and tutorials
- **📰 News Sites**: Content-heavy publications

## 🚀 Get Started

Ready to build your own lightning-fast site?

- 📖 **Documentation**: [Complete guide](https://github.com/lapis-lang/lapis)
- ⭐ **GitHub**: [Star us on GitHub](https://github.com/lapis-lang/lapis)
- 💬 **Community**: [Join discussions](https://github.com/lapis-lang/lapis/discussions)
- 🐛 **Issues**: [Report bugs](https://github.com/lapis-lang/lapis/issues)

## 📈 Performance Metrics

This site demonstrates Lapis's performance capabilities:

- **Build Time**: Sub-second builds for most sites
- **Bundle Size**: Optimized CSS/JS with tree-shaking
- **Image Optimization**: Automatic WebP conversion
- **SEO Score**: Perfect Lighthouse scores
- **Core Web Vitals**: Excellent performance metrics

---

*This comprehensive example site is powered by [Lapis](https://github.com/lapis-lang/lapis), a fast static site generator built with Crystal. Explore the other pages to see more features in action!*