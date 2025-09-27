---
title: "Writing Your First Post"
date: "2024-01-16 14:30:00 UTC"
tags: ["writing", "markdown", "blogging"]
categories: ["tutorials", "content"]
layout: "post"
description: "Master the art of writing great content with Markdown and frontmatter"
---

# Writing Your First Post

Now that you have Lapis set up, let's dive into creating compelling content for your site. This post will cover everything you need to know about writing in Markdown and using frontmatter effectively.

## Understanding Frontmatter

Frontmatter is the YAML section at the top of your Markdown files that contains metadata:

```yaml
---
title: "Your Post Title"
date: "2024-01-16 14:30:00 UTC"
tags: ["tag1", "tag2"]
categories: ["category1"]
layout: "post"
description: "A brief description for SEO"
author: "Your Name"
draft: false
---
```

### Key Frontmatter Fields

- **title**: The title of your post (required)
- **date**: Publication date in ISO format
- **tags**: Array of tags for categorization
- **categories**: Broader content categories
- **layout**: Template to use (default: "post" for posts, "default" for pages)
- **description**: Meta description for SEO
- **draft**: Set to `true` to exclude from builds

## Markdown Basics

Lapis supports full Markdown syntax with some enhancements:

### Headers

```markdown
# H1 Header
## H2 Header
### H3 Header
```

### Text Formatting

```markdown
**Bold text**
*Italic text*
***Bold and italic***
~~Strikethrough~~
`Inline code`
```

### Lists

```markdown
- Unordered list item
- Another item
  - Nested item

1. Ordered list item
2. Another numbered item
```

### Links and Images

```markdown
[Link text](https://example.com)
![Alt text](image.jpg)
```

### Code Blocks

````markdown
```crystal
def hello_world
  puts "Hello from Crystal!"
end
```
````

### Tables

```markdown
| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Row 1    | Data     | More     |
| Row 2    | Data     | More     |
```

### Blockquotes

```markdown
> This is a blockquote.
> It can span multiple lines.
```

## Advanced Features

### Table of Contents

Lapis can automatically generate a table of contents. Enable it in your frontmatter:

```yaml
---
title: "My Post"
toc: true
---
```

### Syntax Highlighting

Code blocks automatically get syntax highlighting:

```javascript
function greet(name) {
  console.log(`Hello, ${name}!`);
}
```

```python
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)
```

### Cross-References

Link to other posts and pages using relative URLs:

```markdown
Check out my [getting started guide](../getting-started/) for setup instructions.
```

## Content Organization

### Using Tags

Tags help readers find related content:

```yaml
tags: ["tutorial", "markdown", "writing", "beginner"]
```

### Categories

Use categories for broader organization:

```yaml
categories: ["tutorials", "content-creation"]
```

### Permalinks

Customize your URL structure in `config.yml`:

```yaml
permalink: "/:year/:month/:day/:title/"
```

## Writing Tips

### 1. Start with an Outline

Before writing, create a rough outline of your main points:

- Introduction
- Main concepts
- Examples
- Conclusion

### 2. Use Clear Headers

Break up your content with descriptive headers that help readers scan your content.

### 3. Include Examples

Code examples and practical demonstrations make your content more valuable.

### 4. Add Visual Elements

Use images, diagrams, and code blocks to break up text and illustrate concepts.

### 5. Write Compelling Descriptions

Your frontmatter description appears in search results and social media previews.

## Publishing Workflow

1. **Draft**: Start with `draft: true` in frontmatter
2. **Review**: Use `lapis serve` to preview your content
3. **Edit**: Refine your writing and formatting
4. **Publish**: Set `draft: false` and run `lapis build`

## What's Next?

Now you know the basics of writing content in Lapis! In the next post, we'll explore:

- Customizing your site's appearance
- Creating custom layouts
- Adding interactive features
- Optimizing for performance

Happy writing! ✍️