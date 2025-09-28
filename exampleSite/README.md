# Lapis Example Site

This is the official example site for [Lapis](https://github.com/lapis-lang/lapis), demonstrating all the key features and capabilities of the static site generator.

## 🎯 Purpose

This example site serves as:
- **Live demo** of Lapis features
- **Reference implementation** for developers
- **Template showcase** for different use cases
- **Testing environment** for new features

## 🚀 Quick Start

From the main Lapis directory:

```bash
# Build the example site
cd exampleSite
../bin/lapis build

# Start development server
../bin/lapis serve
```

Visit `http://localhost:3000` to see the site in action!

## 📁 Site Structure

```
exampleSite/
├── config.yml          # Site configuration with all options
├── content/
│   ├── index.md        # Homepage with shortcodes demo
│   ├── about.md        # About page
│   └── posts/          # Blog posts showcasing features
├── layouts/            # Custom layouts (optional)
├── static/
│   ├── css/           # Enhanced styling
│   ├── js/            # Custom JavaScript
│   └── images/        # Sample images for demos
└── public/            # Generated output (after build)
```

## ✨ Features Demonstrated

### **Content Management**
- YAML frontmatter with all supported fields
- Multiple content types (pages vs posts)
- Tags and categories organization
- Draft content workflow

### **Shortcodes Showcase**
- `{% image %}` - Responsive images with lazy loading
- `{% alert %}` - Styled notification boxes
- `{% button %}` - Call-to-action buttons
- `{% gallery %}` - Image galleries
- `{% highlight %}` - Syntax-highlighted code blocks
- `{% quote %}` - Beautiful blockquotes
- `{% recent_posts %}` - Dynamic content listing

### **Performance Features**
- Automatic image optimization
- RSS/Atom/JSON feeds
- Sitemap generation
- Asset fingerprinting
- Pagination examples

### **SEO & Analytics**
- Meta tags optimization
- Open Graph tags
- Twitter Cards
- Google Analytics integration
- Performance analytics

## 🎨 Customization Examples

The example site shows how to:
- Override default layouts
- Add custom CSS styling
- Implement dark mode
- Create responsive designs
- Add interactive JavaScript
- Configure social sharing

## 🧪 Testing New Features

When developing Lapis features:

1. **Add examples** to this site showcasing the new functionality
2. **Update content** to demonstrate proper usage
3. **Test builds** to ensure everything works correctly
4. **Document changes** in this README

## 📚 Content Guidelines

### **Posts**
All example posts should:
- Demonstrate specific Lapis features
- Include practical code examples
- Show best practices
- Be well-formatted and engaging

### **Pages**
Static pages should showcase:
- Different layout options
- Content organization patterns
- Navigation structures
- SEO optimization

## 🔧 Configuration Reference

The `config.yml` file demonstrates all available options:

```yaml
# Site identity
title: "Lapis Example Site"
description: "Showcasing the power of Crystal-based static site generation"
author: "Lapis Team"

# URL structure
baseurl: "http://localhost:3000"
permalink: "/:year/:month/:day/:title/"

# Performance settings
posts_per_page: 10
excerpt_length: 200

# Feature toggles
markdown:
  syntax_highlighting: true
  toc: true
  smart_quotes: true
```

## 🚀 Deployment

This example site can be deployed to:
- **Netlify**: Drag and drop the `public/` folder
- **Vercel**: Connect the repository
- **GitHub Pages**: Push to `gh-pages` branch
- **Static hosting**: Upload `public/` contents

## 🤝 Contributing

When adding new features to Lapis:

1. Add examples to this site
2. Update relevant documentation
3. Ensure builds work correctly
4. Test performance impact

## 📄 License

This example site content is part of the Lapis project and follows the same MIT license.