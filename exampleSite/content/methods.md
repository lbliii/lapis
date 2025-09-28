---
title: "Site and Page Methods in Lapis"
date: "2025-09-28"
description: "Complete guide to Hugo-compatible site and page methods in Lapis"
tags: ["templates", "methods", "hugo", "documentation"]
---

# Site and Page Methods in Lapis

Lapis provides Hugo-compatible **site and page methods** that give you powerful access to your content, metadata, and site structure. These methods follow Hugo's naming conventions while adding Crystal's performance benefits.

## Site Methods

Access global site information and content collections:

### Basic Site Properties

```html
<!-- Site metadata -->
<title>{{ page.title }} - {{ site.Title }}</title>
<meta name="description" content="{{ site.description }}">
<link rel="canonical" href="{{ site.BaseURL }}{{ page.url }}">

<!-- Site configuration -->
<p>Built with {{ site.generator }}</p>
<p>Version: {{ site.version }}</p>
<p>Environment: {{ site.hugo.environment }}</p>
```

### Content Collections

```html
<!-- All pages -->
<p>Total pages: {{ len site.Pages }}</p>

<!-- Regular pages (excluding sections) -->
{{ range site.RegularPages }}
  <article>
    <h2><a href="{{ .url }}">{{ .title }}</a></h2>
    <p>{{ .summary }}</p>
  </article>
{{ end }}

<!-- Section pages -->
{{ range site.section_pages }}
  <section>
    <h3>{{ .title }}</h3>
    <p>{{ len .children }} pages in this section</p>
  </section>
{{ end }}
```

### Taxonomies

```html
<!-- All tags -->
<div class="tag-cloud">
  {{ range $tag, $pages := site.tags }}
    <a href="/tags/{{ urlize $tag }}" class="tag">
      {{ $tag }} ({{ len $pages }})
    </a>
  {{ end }}
</div>

<!-- All categories -->
<nav class="categories">
  {{ range $category, $pages := site.categories }}
    <a href="/categories/{{ urlize $category }}">
      {{ title $category }}
    </a>
  {{ end }}
</nav>
```

### Site Queries

```html
<!-- Find specific pages -->
{{ $about := site.get_page "/about" }}
{{ if $about }}
  <a href="{{ $about.url }}">{{ $about.title }}</a>
{{ end }}

<!-- Filter pages -->
{{ range site.where "section" "posts" }}
  <article>{{ .title }}</article>
{{ end }}

{{ range site.where "type" "eq" "tutorial" }}
  <div class="tutorial">{{ .title }}</div>
{{ end }}
```

### Sections

```html
<!-- All sections -->
{{ range $section, $pages := site.sections }}
  <section class="section-{{ $section }}">
    <h2>{{ title $section }}</h2>
    <p>{{ len $pages }} pages</p>
  </section>
{{ end }}

<!-- Specific section -->
{{ $blog_posts := site.get_section "blog" }}
{{ range $blog_posts }}
  <article>{{ .title }}</article>
{{ end }}
```

### Helper Methods

```html
<!-- Recent content -->
{{ range site.recent_posts 5 }}
  <article class="recent">
    <h3><a href="{{ .url }}">{{ .title }}</a></h3>
    <time>{{ dateFormat "%B %d" .date }}</time>
  </article>
{{ end }}

<!-- Content by year -->
{{ range $year, $posts := site.posts_by_year }}
  <section class="year-{{ $year }}">
    <h2>{{ $year }}</h2>
    {{ range $posts }}
      <article>{{ .title }}</article>
    {{ end }}
  </section>
{{ end }}

<!-- Tag cloud with weights -->
{{ range $tag, $count := site.tag_cloud }}
  <span class="tag" style="font-size: {{ add 12 (mul $count 2) }}px">
    {{ $tag }}
  </span>
{{ end }}
```

## Page Methods

Access current page information and relationships:

### Basic Page Properties

```html
<!-- Core properties -->
<h1>{{ page.Title }}</h1>
<div class="content">{{ page.Content }}</div>
<p class="summary">{{ page.Summary }}</p>

<!-- Metadata -->
<time datetime="{{ page.Date }}">{{ dateFormat "%B %d, %Y" page.Date }}</time>
<p>Last modified: {{ dateFormat "%B %d, %Y" page.lastmod }}</p>

<!-- URLs -->
<link rel="canonical" href="{{ page.Permalink }}">
<meta property="og:url" content="{{ page.Permalink }}">
```

### Page Status

```html
<!-- Publication status -->
{{ if page.draft }}
  <div class="draft-notice">This is a draft</div>
{{ end }}

{{ if page.future }}
  <div class="future-notice">Scheduled for future publication</div>
{{ end }}

{{ if page.expired }}
  <div class="expired-notice">This content has expired</div>
{{ end }}
```

### Content Metrics

```html
<!-- Reading information -->
<div class="reading-info">
  <span>{{ page.WordCount }} words</span>
  <span>{{ page.ReadingTime }} min read</span>
  {{ if page.truncated }}
    <span>Summary truncated</span>
  {{ end }}
</div>

<!-- Content analysis -->
<div class="content-stats">
  <p>Words: {{ page.word_count }}</p>
  <p>Characters: {{ len page.plain }}</p>
  <p>Paragraphs: {{ len (split page.content "</p>") }}</p>
</div>
```

### Taxonomies

```html
<!-- Tags -->
{{ if page.Tags }}
  <div class="tags">
    {{ range page.Tags }}
      <a href="/tags/{{ urlize . }}" class="tag">{{ . }}</a>
    {{ end }}
  </div>
{{ end }}

<!-- Categories -->
{{ if page.Categories }}
  <nav class="categories">
    {{ range page.Categories }}
      <a href="/categories/{{ urlize . }}">{{ title . }}</a>
    {{ end }}
  </nav>
{{ end }}

<!-- Custom taxonomies -->
{{ range page.get_term "authors" }}
  <span class="author">{{ . }}</span>
{{ end }}
```

### Page Relationships

```html
<!-- Navigation -->
<nav class="page-nav">
  {{ if page.Prev }}
    <a href="{{ page.Prev.url }}" class="prev">
      ← {{ page.Prev.title }}
    </a>
  {{ end }}

  {{ if page.Next }}
    <a href="{{ page.Next.url }}" class="next">
      {{ page.Next.title }} →
    </a>
  {{ end }}
</nav>

<!-- Related content -->
{{ if page.Related }}
  <section class="related">
    <h3>Related Posts</h3>
    {{ range page.Related }}
      <article>
        <h4><a href="{{ .url }}">{{ .title }}</a></h4>
        <p>{{ .summary }}</p>
      </article>
    {{ end }}
  </section>
{{ end }}
```

### Page Hierarchy

```html
<!-- Breadcrumbs -->
<nav class="breadcrumbs">
  {{ range page.ancestors }}
    <a href="{{ .url }}">{{ .title }}</a> /
  {{ end }}
  <span>{{ page.title }}</span>
</nav>

<!-- Section information -->
<div class="section-info">
  <p>Section: {{ page.Section }}</p>
  <p>Type: {{ page.Type }}</p>
  <p>Kind: {{ page.Kind }}</p>
</div>

<!-- Children (for section pages) -->
{{ if page.Children }}
  <section class="children">
    <h3>In This Section</h3>
    {{ range page.Children }}
      <article>
        <h4><a href="{{ .url }}">{{ .title }}</a></h4>
        <p>{{ .description }}</p>
      </article>
    {{ end }}
  </section>
{{ end }}

<!-- Siblings -->
{{ if page.siblings }}
  <nav class="siblings">
    <h3>Other pages in {{ page.parent.title }}</h3>
    {{ range page.siblings }}
      <a href="{{ .url }}">{{ .title }}</a>
    {{ end }}
  </nav>
{{ end }}
```

### Page Kind Detection

```html
<!-- Conditional content based on page type -->
{{ if page.is_home? }}
  <div class="home-content">Welcome to the site!</div>
{{ else if page.is_section? }}
  <div class="section-header">Section: {{ page.title }}</div>
{{ else if page.is_page? }}
  <article class="single-page">{{ page.content }}</article>
{{ end }}

<!-- Layout and type -->
<body class="page-{{ page.type }} layout-{{ page.layout }}">
```

### File Information

```html
<!-- File metadata -->
<div class="file-info">
  <p>File: {{ page.file.filename }}</p>
  <p>Directory: {{ page.file.dir }}</p>
  <p>Extension: {{ page.file.extension }}</p>
  <p>Base name: {{ page.file.base_name }}</p>
</div>

<!-- Full file path -->
<meta name="source-file" content="{{ page.file_path }}">
```

### Table of Contents

```html
<!-- Auto-generated TOC -->
{{ if page.toc }}
  <aside class="table-of-contents">
    <h3>Contents</h3>
    {{ page.table_of_contents }}
  </aside>
{{ end }}
```

### Custom Parameters

```html
<!-- Access frontmatter -->
{{ range $key, $value := page.Params }}
  <meta name="custom-{{ $key }}" content="{{ $value }}">
{{ end }}

<!-- Specific parameters -->
{{ if page.param "featured" }}
  <div class="featured-badge">Featured</div>
{{ end }}

{{ $author := page.param "author" }}
{{ if $author }}
  <p class="author">By {{ $author }}</p>
{{ end }}
```

## Advanced Examples

### Dynamic Section Navigation

```html
<nav class="section-nav">
  {{ $current_section := page.current_section }}
  {{ if $current_section }}
    <h3>{{ $current_section.title }}</h3>
    {{ range $current_section.children }}
      <a href="{{ .url }}"
         class="nav-item{{ if eq .url page.url }} active{{ end }}">
        {{ .title }}
      </a>
    {{ end }}
  {{ end }}
</nav>
```

### Content Analysis Dashboard

```html
<div class="content-dashboard">
  <div class="metric">
    <h4>Content Stats</h4>
    <p>{{ len site.Pages }} total pages</p>
    <p>{{ len site.RegularPages }} articles</p>
    <p>{{ len site.tags }} unique tags</p>
  </div>

  <div class="metric">
    <h4>This Page</h4>
    <p>{{ page.word_count }} words</p>
    <p>{{ page.reading_time }} min read</p>
    <p>{{ len page.tags }} tags</p>
  </div>
</div>
```

### Smart Related Content

```html
{{ $related := page.related }}
{{ if $related }}
  <section class="related-content">
    <h3>You Might Also Like</h3>
    {{ range first 3 $related }}
      <article class="related-post">
        <h4><a href="{{ .url }}">{{ .title }}</a></h4>
        <p>{{ .summary }}</p>
        <div class="meta">
          {{ dateFormat "%B %d" .date }} •
          {{ .reading_time }} min read
        </div>
      </article>
    {{ end }}
  </section>
{{ end }}
```

Site and page methods provide the foundation for powerful, data-driven templates in Lapis. They offer the same flexibility as Hugo while providing better performance and more intuitive syntax options.