# Lapis

A fast static site generator built in Crystal, inspired by Hugo and Sphinx.

[![Crystal](https://img.shields.io/badge/crystal-1.0+-blue.svg)](https://crystal-lang.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## ⚡ Features

- **Lightning Fast**: Built with Crystal for maximum performance
- **Simple to Use**: Hugo-inspired CLI with sensible defaults
- **Powerful**: Sphinx-inspired documentation features
- **Live Reload**: Development server with automatic rebuilding
- **Markdown**: Full support with YAML frontmatter
- **Themes**: Beautiful responsive themes with dark mode
- **Tags & Categories**: Organize content effectively
- **Cross-References**: Automatic linking between pages
- **Mobile Friendly**: Responsive design out of the box

## 🚀 Quick Start

### Installation

Build from source (requires Crystal 1.0+):

```bash
git clone https://github.com/lapis-lang/lapis.git
cd lapis
shards install
crystal build src/lapis.cr --release -o bin/lapis
```

### Create Your First Site

```bash
# Create a new site
./bin/lapis init my-blog

# Enter the directory
cd my-blog

# Start the development server
../bin/lapis serve
```

Visit `http://localhost:3000` to see your site!

### Add Content

```bash
# Create a new page
lapis new page "About"

# Create a new blog post
lapis new post "My First Post"

# Build the static site
lapis build
```

## 📁 Project Structure

```
my-blog/
├── config.yml          # Site configuration
├── content/             # Your content files
│   ├── index.md        # Homepage
│   ├── about.md        # Pages
│   └── posts/          # Blog posts
│       └── welcome.md
├── layouts/            # Custom layouts (optional)
├── static/             # Static assets
│   ├── css/
│   ├── js/
│   └── images/
└── public/             # Generated site (after build)
```

## 📝 Writing Content

Content is written in Markdown with YAML frontmatter:

```markdown
---
title: "My First Post"
date: "2024-01-15 10:00:00 UTC"
tags: ["hello", "world"]
categories: ["blog"]
layout: "post"
description: "My very first blog post"
---

# My First Post

This is my first post written in **Markdown**!

## Features I Love

- Easy to write
- Fast to build
- Beautiful output

```

### Frontmatter Fields

- `title`: Post/page title (required)
- `date`: Publication date in ISO format
- `tags`: Array of tags for organization
- `categories`: Content categories
- `layout`: Template to use (default: "post" for posts, "default" for pages)
- `description`: Meta description for SEO
- `author`: Author name
- `draft`: Set to `true` to exclude from builds
- `toc`: Enable table of contents generation

## ⚙️ Configuration

Configure your site in `config.yml`:

```yaml
title: "My Lapis Site"
baseurl: "https://mysite.com"
description: "A beautiful site built with Lapis"
author: "Your Name"

# Build settings
output_dir: "public"
permalink: "/:year/:month/:day/:title/"

# Server settings
port: 3000
host: "localhost"

# Markdown settings
markdown:
  syntax_highlighting: true
  toc: true
  smart_quotes: true
  footnotes: true
  tables: true
```

## 🎨 Themes and Customization

### Using the Default Theme

Lapis comes with a beautiful responsive theme that supports:

- Clean, readable typography
- Responsive design for all devices
- Dark mode support
- Syntax highlighting for code
- Tag and category organization

### Custom Layouts

Create custom layouts in the `layouts/` directory:

```html
<!-- layouts/custom.html -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>{{ title }} - {{ site.title }}</title>
</head>
<body>
  <h1>{{ title }}</h1>
  {{ content }}
</body>
</html>
```

Use in your content frontmatter:

```yaml
---
title: "Custom Page"
layout: "custom"
---
```

### Custom Styling

Add custom CSS in `static/css/custom.css` and reference it in your layouts.

## 🔧 CLI Commands

```bash
# Create a new site
lapis init <site-name>

# Build the static site
lapis build

# Start development server with live reload
lapis serve

# Create new content
lapis new page <title>
lapis new post <title>

# Show help
lapis help
```

## 🏗️ Development

### Building from Source

```bash
git clone https://github.com/lapis-lang/lapis.git
cd lapis
shards install
crystal build src/lapis.cr
```

### Running Tests

```bash
crystal spec
```

### Code Quality

```bash
# Run linter
shards run ameba

# Format code
crystal tool format
```

## 📚 Examples

Check out the `examples/` directory for complete example sites:

- `examples/blog/` - A complete blog setup with multiple posts
- See the live examples at [lapis-examples.com](https://lapis-examples.com)

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by [Hugo](https://gohugo.io/) for its speed and simplicity
- Inspired by [Sphinx](https://www.sphinx-doc.org/) for its documentation features
- Built with [Crystal](https://crystal-lang.org/) for performance and developer happiness

## 📞 Support

- **Documentation**: [GitHub Wiki](https://github.com/lapis-lang/lapis/wiki)
- **Issues**: [GitHub Issues](https://github.com/lapis-lang/lapis/issues)
- **Discussions**: [GitHub Discussions](https://github.com/lapis-lang/lapis/discussions)

---

Built with ❤️ using Crystal