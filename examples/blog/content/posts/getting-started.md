---
title: "Getting Started with Lapis"
date: "2024-01-15 10:00:00 UTC"
tags: ["tutorial", "getting-started", "lapis"]
categories: ["tutorials"]
layout: "post"
description: "Learn how to create your first Lapis static site in just a few minutes"
---

# Getting Started with Lapis

Welcome to Lapis! This tutorial will walk you through creating your first static site with our fast, Crystal-powered generator.

## What is Lapis?

Lapis is a modern static site generator that combines:

- **Speed**: Written in Crystal for lightning-fast builds
- **Simplicity**: Hugo-inspired commands and structure
- **Power**: Sphinx-inspired documentation features
- **Flexibility**: Customizable themes and layouts

## Installation

First, make sure you have Crystal installed on your system. Then you can build Lapis from source:

```bash
git clone https://github.com/lapis-lang/lapis.git
cd lapis
shards install
crystal build src/lapis.cr --release
```

## Creating Your First Site

Creating a new site is simple:

```bash
# Create a new site
lapis init my-first-site

# Enter the directory
cd my-first-site

# Check out the structure
ls -la
```

This creates a complete site structure:

```
my-first-site/
├── config.yml          # Site configuration
├── content/             # Your content files
│   ├── index.md        # Homepage
│   └── posts/          # Blog posts
├── layouts/            # Custom layouts (optional)
├── static/             # Static assets
│   ├── css/
│   └── js/
└── public/             # Generated site (after build)
```

## Writing Content

Content is written in Markdown with YAML frontmatter:

```markdown
---
title: "My First Post"
date: "2024-01-15"
tags: ["hello", "world"]
layout: "post"
---

# My First Post

This is my first post written in **Markdown**!

## Features I Love

- Easy to write
- Fast to build
- Beautiful output
```

## Building and Serving

To build your site:

```bash
# Build the static site
lapis build

# Start development server with live reload
lapis serve
```

The development server will watch for changes and automatically rebuild your site. Visit `http://localhost:3000` to see your site!

## Next Steps

Now that you have a basic site running, you can:

1. **Add more content**: Create pages with `lapis new page "About"`
2. **Write blog posts**: Use `lapis new post "My Second Post"`
3. **Customize styling**: Edit CSS files in the `static/css/` directory
4. **Configure your site**: Update `config.yml` with your details

## Getting Help

- Check the [documentation](https://github.com/lapis-lang/lapis)
- Look at [example sites](https://github.com/lapis-lang/lapis/tree/main/examples)
- Join our community discussions

Happy site building! 🚀