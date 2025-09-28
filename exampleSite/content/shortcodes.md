---
title: "Shortcodes Showcase"
layout: "page"
description: "Complete showcase of all available shortcodes in Lapis with examples and usage instructions"
toc: true
---

# Shortcodes Showcase

Lapis provides powerful shortcodes that transform your content with dynamic widgets and components. This page demonstrates all available shortcodes with practical examples.

## 🚨 Alert Boxes

Alert shortcodes create styled notification boxes for different types of messages.

### Basic Usage
```markdown
{% alert "info" %}Your information message here{% endalert %}
{% alert "success" %}Your success message here{% endalert %}
{% alert "warning" %}Your warning message here{% endalert %}
{% alert "error" %}Your error message here{% endalert %}
```

### Live Examples

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

## 🔘 Interactive Buttons

Button shortcodes create styled call-to-action buttons with different styles.

### Basic Usage
```markdown
{% button "https://example.com" "Button Text" "primary" %}
{% button "https://example.com" "Button Text" "secondary" %}
{% button "https://example.com" "Button Text" "outline" %}
```

### Live Examples

{% button "https://github.com/lapis-lang/lapis" "View on GitHub" "primary" %}

{% button "https://github.com/lapis-lang/lapis/discussions" "Join Discussions" "secondary" %}

{% button "https://github.com/lapis-lang/lapis/issues" "Report Issues" "outline" %}

## 💻 Code Highlighting

Highlight shortcodes provide syntax-highlighted code blocks with copy functionality.

### Basic Usage
```markdown
{% highlight "language" %}
Your code here
{% endhighlight %}
```

### Live Examples

#### Crystal Code
{% highlight "crystal" %}
# Fast static site generation with Crystal
class SiteGenerator
  def initialize(@config : Config)
    @content = ContentLoader.new
    @templates = TemplateEngine.new
  end

  def build
    pages = @content.load_pages
    pages.each do |page|
      html = @templates.render(page)
      write_output(page.url, html)
    end
  end
end
{% endhighlight %}

#### JavaScript Code
{% highlight "javascript" %}
// Modern JavaScript with ES6+ features
const siteGenerator = {
  async build() {
    const pages = await this.loadPages();
    const templates = await this.loadTemplates();
    
    for (const page of pages) {
      const html = await this.renderPage(page, templates);
      await this.writeOutput(page.url, html);
    }
  },
  
  async loadPages() {
    return fetch('/api/pages')
      .then(response => response.json());
  }
};
{% endhighlight %}

#### Python Code
{% highlight "python" %}
# Python static site generator example
import os
import json
from pathlib import Path

class SiteGenerator:
    def __init__(self, config_path):
        with open(config_path) as f:
            self.config = json.load(f)
    
    def build(self):
        pages = self.load_pages()
        for page in pages:
            html = self.render_page(page)
            self.write_output(page['url'], html)
    
    def load_pages(self):
        content_dir = Path(self.config['content_dir'])
        return [self.parse_page(f) for f in content_dir.glob('**/*.md')]
{% endhighlight %}

## 🖼️ Responsive Images

Image shortcodes generate responsive images with automatic optimization and WebP conversion.

### Basic Usage
```markdown
{% image "path/to/image.jpg" "Alt text" %}
```

### Live Examples

{% image "https://via.placeholder.com/800x400/4f46e5/ffffff?text=Lapis+SSG" "Lapis Static Site Generator" %}

{% alert "info" %}
**Note**: The image shortcode automatically generates multiple sizes and WebP versions for optimal performance across all devices.
{% endalert %}

## 💬 Beautiful Quotes

Quote shortcodes create elegant blockquotes with attribution.

### Basic Usage
```markdown
{% quote "Author Name" "Source" %}
Quote text goes here.
{% endquote %}
```

### Live Examples

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

## 📺 YouTube Embeds

YouTube shortcodes create responsive video embeds.

### Basic Usage
```markdown
{% youtube "video_id" %}
```

### Live Example

{% youtube "dQw4w9WgXcQ" %}

{% alert "info" %}
**Performance**: YouTube embeds are loaded lazily to improve page performance. The video only loads when the user scrolls to it.
{% endalert %}

## 🖼️ Image Galleries

Gallery shortcodes create responsive image galleries from a folder.

### Basic Usage
```markdown
{% gallery "folder/path" %}
```

### Live Example

{% gallery "https://via.placeholder.com/300x200/ef4444/ffffff?text=Image+1,https://via.placeholder.com/300x200/10b981/ffffff?text=Image+2,https://via.placeholder.com/300x200/3b82f6/ffffff?text=Image+3" %}

{% alert "info" %}
**Note**: Gallery shortcodes automatically create responsive grids with lightbox functionality for an enhanced viewing experience.
{% endalert %}

## 📋 Table of Contents

TOC shortcodes generate automatic table of contents for long content.

### Basic Usage
```markdown
{% toc %}
```

### Live Example

{% toc %}

{% alert "info" %}
**Automatic Generation**: The TOC shortcode automatically scans your content for headings and generates a navigation structure.
{% endalert %}

## 📰 Recent Posts

Recent posts shortcodes display dynamic lists of recent content.

### Basic Usage
```markdown
{% recent_posts 5 %}
```

### Live Example

{% recent_posts 3 %}

## 🎨 Custom Shortcodes

You can also create custom shortcodes for your specific needs.

### Example Custom Shortcode
```crystal
# In your shortcode processor
def generate_custom_widget(content : String, params : Hash(String, String)) : String
  type = params["type"]? || "default"
  title = params["title"]? || "Widget"
  
  <<-HTML.strip
  <div class="custom-widget widget-#{type}">
    <h3>#{title}</h3>
    <div class="widget-content">
      #{content}
    </div>
  </div>
  HTML
end
```

### Usage
```markdown
{% custom_widget "type=info" "title=Custom Widget" %}
This is custom widget content.
{% endcustom_widget %}
```

## 🚀 Performance Benefits

Shortcodes provide several performance benefits:

1. **Lazy Loading**: Images and videos load only when needed
2. **Optimization**: Automatic image compression and WebP conversion
3. **Caching**: Shortcode output is cached for faster rebuilds
4. **Minification**: Generated HTML is automatically minified

## 🎯 Best Practices

### When to Use Shortcodes

- **Alerts**: For important notices and information
- **Buttons**: For call-to-action elements
- **Code**: For syntax-highlighted code examples
- **Images**: For responsive, optimized images
- **Quotes**: For attributed quotations
- **Videos**: For embedded media content

### Shortcode Guidelines

1. **Keep content concise**: Shortcodes work best with focused content
2. **Use appropriate types**: Choose the right alert type or button style
3. **Provide alt text**: Always include descriptive alt text for images
4. **Test responsiveness**: Ensure shortcodes work on all devices
5. **Consider performance**: Use shortcodes judiciously to maintain speed

## 🔧 Advanced Usage

### Conditional Shortcodes
```markdown
{{ if page.featured }}
{% alert "success" %}This is a featured post!{% endalert %}
{{ end }}
```

### Dynamic Shortcodes
```markdown
{% button "{{ page.github_url }}" "View Source" "primary" %}
```

### Nested Shortcodes
```markdown
{% alert "info" %}
Check out this code example:
{% highlight "crystal" %}
puts "Hello, World!"
{% endhighlight %}
{% endalert %}
```

---

*Shortcodes make Lapis content creation powerful and flexible. Use them to create engaging, interactive content that looks professional and performs excellently.*
