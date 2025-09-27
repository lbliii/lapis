---
title: "Customizing Your Lapis Site"
date: "2024-01-17 16:45:00 UTC"
tags: ["customization", "themes", "css", "advanced"]
categories: ["tutorials", "design"]
layout: "post"
description: "Learn how to customize your Lapis site with themes, layouts, and custom styling"
---

# Customizing Your Lapis Site

One of Lapis's strengths is its flexibility. This guide will show you how to customize every aspect of your site, from basic styling to completely custom layouts.

## Configuration Options

Start by customizing your `config.yml` file:

```yaml
title: "My Amazing Site"
baseurl: "https://mysite.com"
description: "Building the future, one post at a time"
author: "Your Name"

# Customize URLs
permalink: "/:year/:title/"

# Server settings
port: 4000
host: "0.0.0.0"

# Markdown features
markdown:
  syntax_highlighting: true
  toc: true
  smart_quotes: true
  footnotes: true
  tables: true
```

## Custom Styling

### Override Default Styles

Create a `static/css/custom.css` file to override default styles:

```css
/* Custom color scheme */
:root {
  --primary-color: #6366f1;
  --secondary-color: #8b5cf6;
  --accent-color: #f59e0b;
}

/* Custom header styling */
.site-header {
  background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
  color: white;
}

.site-title {
  color: white;
  font-weight: 800;
  letter-spacing: -0.02em;
}

/* Custom post styling */
.post-header h1 {
  background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}
```

Then reference it in your layout:

```html
<link rel="stylesheet" href="/css/style.css">
<link rel="stylesheet" href="/css/custom.css">
```

## Custom Layouts

### Creating Layout Templates

Create custom layouts in the `layouts/` directory:

```html
<!-- layouts/minimal.html -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>{{ title }}</title>
  <style>
    body {
      font-family: Georgia, serif;
      max-width: 600px;
      margin: 0 auto;
      padding: 2rem;
      line-height: 1.7;
    }
  </style>
</head>
<body>
  <article>
    <h1>{{ title }}</h1>
    {{ content }}
  </article>
</body>
</html>
```

### Using Custom Layouts

Specify the layout in your content's frontmatter:

```yaml
---
title: "Minimalist Post"
layout: "minimal"
---
```

## Advanced Template Features

### Template Variables

Lapis provides several built-in variables:

```html
<!-- Site information -->
{{ site.title }}
{{ site.description }}
{{ site.author }}
{{ site.baseurl }}

<!-- Content information -->
{{ title }}
{{ content }}
{{ date }}
{{ date_formatted }}
{{ url }}
{{ description }}

<!-- Collections -->
{{ tags }}
{{ categories }}
```

### Conditional Content

Show content based on conditions:

```html
{{ if date }}
  <time datetime="{{ date }}">{{ date_formatted }}</time>
{{ endif }}

{{ if tags }}
  <div class="tags">{{ tags }}</div>
{{ endif }}
```

## Theme Development

### Creating a Complete Theme

Organize your theme in the `themes/` directory:

```
themes/my-theme/
├── layouts/
│   ├── default.html
│   ├── post.html
│   └── page.html
├── static/
│   ├── css/
│   │   └── theme.css
│   ├── js/
│   │   └── theme.js
│   └── images/
└── theme.yml
```

### Theme Configuration

Create a `theme.yml` file:

```yaml
name: "My Custom Theme"
version: "1.0.0"
description: "A beautiful theme for Lapis"
author: "Your Name"
homepage: "https://github.com/username/my-theme"

features:
  - responsive
  - dark-mode
  - syntax-highlighting
  - reading-time
```

## Advanced Customizations

### Custom Content Types

Create specialized content types by using custom layouts and frontmatter:

```yaml
---
title: "Product Review: Amazing Widget"
layout: "review"
product: "Amazing Widget"
rating: 5
pros: ["Fast", "Reliable", "Easy to use"]
cons: ["Expensive"]
---
```

### JavaScript Enhancements

Add interactivity with custom JavaScript:

```javascript
// static/js/enhancements.js

// Reading progress indicator
function updateReadingProgress() {
  const article = document.querySelector('article');
  const scrollPercent = (window.scrollY / (article.offsetHeight - window.innerHeight)) * 100;
  document.querySelector('.reading-progress').style.width = Math.min(scrollPercent, 100) + '%';
}

window.addEventListener('scroll', updateReadingProgress);

// Table of contents generator
function generateTOC() {
  const headings = document.querySelectorAll('h2, h3, h4');
  const toc = document.querySelector('.toc');

  headings.forEach((heading, index) => {
    const link = document.createElement('a');
    link.href = `#heading-${index}`;
    link.textContent = heading.textContent;
    heading.id = `heading-${index}`;
    toc.appendChild(link);
  });
}

document.addEventListener('DOMContentLoaded', generateTOC);
```

### CSS Grid Layouts

Create sophisticated layouts with CSS Grid:

```css
.content-grid {
  display: grid;
  grid-template-columns: 250px 1fr 200px;
  grid-template-areas:
    "sidebar content toc";
  gap: 2rem;
  max-width: 1200px;
  margin: 0 auto;
}

.sidebar { grid-area: sidebar; }
.main-content { grid-area: content; }
.table-of-contents { grid-area: toc; }

@media (max-width: 768px) {
  .content-grid {
    grid-template-columns: 1fr;
    grid-template-areas:
      "content"
      "toc"
      "sidebar";
  }
}
```

## Performance Optimization

### Image Optimization

Use responsive images and proper formats:

```html
<picture>
  <source srcset="image.webp" type="image/webp">
  <source srcset="image.jpg" type="image/jpeg">
  <img src="image.jpg" alt="Description" loading="lazy">
</picture>
```

### CSS Optimization

Use CSS custom properties for maintainable styles:

```css
:root {
  --font-family-base: system-ui, -apple-system, sans-serif;
  --font-family-mono: 'SF Mono', Monaco, 'Cascadia Code', monospace;
  --font-size-base: 1.125rem;
  --line-height-base: 1.7;
  --color-text: #1f2937;
  --color-text-light: #6b7280;
  --color-primary: #3b82f6;
  --spacing-unit: 1rem;
}
```

## Tips for Success

### 1. Keep It Simple

Start with small customizations and build up complexity gradually.

### 2. Test Responsiveness

Always test your customizations on different screen sizes.

### 3. Optimize for Speed

Keep CSS and JavaScript minimal for fast loading times.

### 4. Document Your Changes

Comment your custom CSS and maintain a changelog for your theme.

### 5. Use Version Control

Track your customizations with Git to easily revert changes.

## What's Next?

With these customization techniques, you can create a truly unique Lapis site. In future posts, we'll explore:

- Building dynamic features with JavaScript
- Integrating with external services
- Advanced SEO optimization
- Performance monitoring and analytics

Happy customizing! 🎨