---
title: "Building a Modern Blog with Lapis"
date: "2024-01-15 10:00:00 UTC"
tags: ["tutorial", "blogging", "crystal", "static-sites"]
categories: ["tutorials"]
layout: "post"
description: "Complete guide to building a modern, fast blog with Lapis static site generator"
author: "Lapis Team"
reading_time: 8
featured: true
series: "Getting Started"
---

# Building a Modern Blog with Lapis

Creating a modern blog that's fast, SEO-optimized, and developer-friendly doesn't have to be complicated. With Lapis, you can build a professional blog in minutes and deploy it anywhere.

## Why Choose Lapis for Blogging?

{% alert "info" %}
**Perfect for Bloggers**: Lapis combines the simplicity of static sites with the power of modern tooling, making it ideal for content creators who want to focus on writing.
{% endalert %}

### Key Benefits

- **⚡ Lightning Fast**: Sub-second builds mean you can iterate quickly
- **📱 Mobile-First**: Responsive design out of the box
- **🔍 SEO Ready**: Automatic sitemaps, meta tags, and structured data
- **🎨 Beautiful Themes**: Professional designs that work on all devices
- **🛠️ Developer Friendly**: Modern tooling with live reload and hot reload

## Getting Started

### 1. Install Lapis

```bash
# Clone the repository
git clone https://github.com/lapis-lang/lapis.git
cd lapis

# Install dependencies
shards install

# Build Lapis
crystal build src/lapis.cr -o bin/lapis
```

### 2. Create Your Blog

```bash
# Initialize a new site
bin/lapis init my-blog
cd my-blog

# Start the development server
bin/lapis serve
```

Visit `http://localhost:3000` to see your new blog!

## Content Structure

Lapis uses a simple, intuitive content structure:

```
my-blog/
├── config.yml          # Site configuration
├── content/            # Your content files
│   ├── index.md       # Homepage
│   ├── about.md       # About page
│   └── posts/         # Blog posts
│       ├── _index.md  # Posts listing page
│       └── welcome.md # Your first post
├── layouts/           # Custom layouts (optional)
├── static/            # Static assets
│   ├── css/
│   ├── js/
│   └── images/
└── public/            # Generated site
```

## Writing Your First Post

Create a new post by adding a Markdown file to the `content/posts/` directory:

```markdown
---
title: "My First Blog Post"
date: "2024-01-15 10:00:00 UTC"
tags: ["welcome", "blogging"]
categories: ["personal"]
description: "Welcome to my new blog built with Lapis!"
---

# My First Blog Post

Welcome to my new blog! This is my first post, and I'm excited to share my thoughts with you.

## What You Can Expect

I'll be writing about:
- Technology and programming
- Personal experiences
- Tutorials and guides
- Industry insights

## Getting Started

{% button "https://github.com/lapis-lang/lapis" "Try Lapis" "primary" %}

Thanks for reading, and welcome to the blog!
```

## Frontmatter Fields

Lapis supports comprehensive frontmatter for rich metadata:

```yaml
---
title: "Post Title"                    # Required
date: "2024-01-15 10:00:00 UTC"       # Publication date
tags: ["tag1", "tag2"]                 # Tags for organization
categories: ["category1"]              # Categories
layout: "post"                         # Template to use
description: "Meta description"        # SEO description
author: "Author Name"                  # Author name
draft: false                           # Hide from builds
featured: true                         # Mark as featured
reading_time: 5                        # Estimated reading time
series: "Series Name"                  # Part of a series
---
```

## Using Shortcodes

Enhance your content with powerful shortcodes:

### Alert Boxes
```markdown
{% alert "info" %}This is an informational alert!{% endalert %}
{% alert "success" %}Great job!{% endalert %}
{% alert "warning" %}Important notice!{% endalert %}
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

### Interactive Buttons
```markdown
{% button "https://example.com" "Visit Site" "primary" %}
```

### Beautiful Quotes
```markdown
{% quote "Author Name" "Source" %}
Quote text goes here.
{% endquote %}
```

## Customizing Your Theme

### Basic Customization

Add custom CSS to `static/css/custom.css`:

```css
/* Custom styles */
.site-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.post-content {
  font-family: 'Georgia', serif;
  line-height: 1.7;
}

.code-highlight {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 1rem;
}
```

### Custom Layouts

Create custom layouts in `layouts/`:

```html
<!-- layouts/custom-post.html -->
{{ extends "baseof" }}

{{ block "main" }}
<article class="custom-post">
  <header>
    <h1>{{ title }}</h1>
    <div class="post-meta">
      <time>{{ date }}</time>
      <span class="reading-time">{{ reading_time }} min read</span>
    </div>
  </header>
  
  <div class="post-content">
    {{ content }}
  </div>
</article>
{{ endblock }}
```

## SEO Optimization

Lapis automatically handles SEO optimization:

### Automatic Features
- Meta tag generation
- Open Graph tags
- Twitter Cards
- Structured data (JSON-LD)
- Sitemap generation
- robots.txt creation

### Configuration
```yaml
# config.yml
plugins:
  seo:
    enabled: true
    generate_sitemap: true
    generate_robots_txt: true
    auto_meta_tags: true
    structured_data: true
    social_cards: true
```

## Performance Optimization

### Build Performance
```yaml
build:
  incremental: true      # Only rebuild changed files
  parallel: true         # Use multiple CPU cores
  cache_dir: ".lapis-cache"
  max_workers: 4
```

### Asset Optimization
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
      output: "assets/css/main.min.css"
```

## Content Organization

### Tags and Categories
```yaml
# In your post frontmatter
tags: ["crystal", "tutorial", "web-development"]
categories: ["programming", "tutorials"]
```

### Series
```yaml
# Group related posts
series: "Getting Started with Lapis"
```

### Custom Taxonomies
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
```

## Deployment

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
      - uses: actions/checkout@v2
      - name: Setup Crystal
        uses: oprypin/crystal-setup-action@v1
      - name: Install dependencies
        run: shards install
      - name: Build site
        run: crystal build src/lapis.cr -o bin/lapis && bin/lapis build
      - name: Deploy
        run: # Your deployment command
```

## Advanced Features

### Multi-format Output
```yaml
outputs:
  single: ["html", "json", "llm"]
  home: ["html", "rss"]
  list: ["html", "rss"]
```

### Analytics Integration
```yaml
plugins:
  analytics:
    enabled: true
    providers:
      google_analytics:
        tracking_id: "GA-XXXXXXXXX"
        enabled: true
```

### Live Reload
```yaml
live_reload:
  enabled: true
  websocket_path: "/ws"
  debounce_ms: 300
```

## Best Practices

### Content Writing
1. **Use descriptive titles**: Help readers understand what they'll learn
2. **Add meta descriptions**: Improve SEO and social sharing
3. **Include relevant tags**: Help readers find related content
4. **Use shortcodes**: Enhance content with interactive elements
5. **Optimize images**: Use the image shortcode for responsive images

### Performance
1. **Enable incremental builds**: Faster development workflow
2. **Optimize assets**: Minify CSS and JavaScript
3. **Use appropriate image formats**: WebP for modern browsers
4. **Leverage caching**: Configure appropriate cache headers

### SEO
1. **Write compelling meta descriptions**: Improve click-through rates
2. **Use semantic HTML**: Better accessibility and SEO
3. **Include alt text**: Describe images for screen readers
4. **Structure content**: Use proper heading hierarchy

## Troubleshooting

### Common Issues

**Build Errors:**
```bash
# Check for syntax errors
lapis build --verbose

# Clean build cache
rm -rf .lapis-cache
lapis build
```

**Performance Issues:**
```bash
# Profile build performance
lapis build --profile

# Check memory usage
lapis build --memory-profile
```

**Content Issues:**
```bash
# Validate content
lapis build --validate

# Check for broken links
lapis build --check-links
```

## Next Steps

Now that you have a working blog, consider these next steps:

1. **Customize the theme**: Make it your own
2. **Add more content**: Write about your interests
3. **Optimize for SEO**: Improve search rankings
4. **Set up analytics**: Track your audience
5. **Deploy to production**: Share your blog with the world

{% alert "success" %}
**Congratulations!** You've successfully created a modern blog with Lapis. The combination of Crystal's performance and Lapis's developer experience makes it an excellent choice for content creators.
{% endalert %}

---

*Ready to start your blogging journey? [Get started with Lapis today](https://github.com/lapis-lang/lapis) and join the community of developers building fast, beautiful static sites.*
