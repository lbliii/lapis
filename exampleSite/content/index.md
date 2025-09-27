---
title: "Lapis SSG"
layout: "home"
description: "The official example site showcasing Crystal-powered static site generation"
---

# Welcome to Lapis! ⚡

This is the **official example site** for Lapis, demonstrating the power and flexibility of Crystal-based static site generation. Explore the features, see the code, and get inspired!

{% recent_posts 5 %}

## Features Showcased

- ⚡ **Performance**: Crystal-powered builds in milliseconds
- 🎨 **Shortcodes**: Dynamic content widgets and components
- 📱 **Responsive**: Mobile-first design with dark mode
- 🔍 **SEO Ready**: Automatic sitemaps, feeds, and meta tags
- 🚀 **Modern DX**: Live reload, analytics, and smart templates

## Shortcodes Demo

### Alert Boxes
{% alert "info" %}This is an info alert showcasing the alert shortcode!{% endalert %}

{% alert "success" %}Build completed successfully with excellent performance!{% endalert %}

### Interactive Elements
{% button "https://github.com/lapis-lang/lapis" "View on GitHub" "primary" %}

### Code Highlighting
{% highlight "crystal" %}
# Fast static site generation
def build_site
  content = load_markdown_files
  html = process_templates(content)
  write_optimized_output(html)
end
{% endhighlight %}

## Get Started

Ready to build your own Lightning-fast site?

- 📖 Read the [documentation](https://github.com/lapis-lang/lapis)
- ⭐ Star us on [GitHub](https://github.com/lapis-lang/lapis)
- 💬 Join the [discussions](https://github.com/lapis-lang/lapis/discussions)

---

*This blog is powered by [Lapis](https://github.com/lapis-lang/lapis), a fast static site generator built with Crystal.*