---
title: "Template Functions in Lapis"
date: "2025-09-28"
description: "Comprehensive guide to template functions in Lapis"
tags: ["templates", "functions", "documentation"]
---

# Template Functions in Lapis

Lapis provides a comprehensive set of **template functions** that make your templates powerful and expressive. These functions follow established conventions while adding developer-friendly alternatives.

## String Functions

Transform and manipulate text with ease:

```html
<!-- Text transformations -->
<h1>{{ upper "hello world" }}</h1>        <!-- HELLO WORLD -->
<p>{{ lower "SHOUT TEXT" }}</p>           <!-- shout text -->
<span>{{ title "article title" }}</span>  <!-- Article Title -->

<!-- String manipulation -->
{{ trim "  spaced text  " }}              <!-- "spaced text" -->
{{ replace "Hello World" "World" "Lapis" }} <!-- "Hello Lapis" -->
{{ substr "Crystal Lang" 0 7 }}           <!-- "Crystal" -->

<!-- URL-friendly strings -->
{{ slugify "My Blog Post!" }}             <!-- "my-blog-post" -->
{{ urlize "Hello World" }}                <!-- "hello-world" -->

<!-- Advanced formatting -->
{{ truncate "Long content here..." 20 "..." }}
{{ printf "Hello %s!" "World" }}
```

## Collection Functions

Work with arrays and lists efficiently:

```html
<!-- Array information -->
<p>Total posts: {{ len site.pages }}</p>

<!-- Array manipulation -->
{{ $tags := slice "crystal" "web" "ssg" }}
<p>First tag: {{ first $tags }}</p>
<p>Last tag: {{ last $tags }}</p>

<!-- Sorting and filtering -->
{{ range sort site.tags }}
  <span class="tag">{{ . }}</span>
{{ end }}

{{ range reverse site.recent_posts }}
  <article>{{ .title }}</article>
{{ end }}

<!-- Unique values -->
{{ $unique_categories := uniq site.categories }}
```

## Math Functions

Perform calculations in templates:

```html
<!-- Basic arithmetic -->
<p>Total: {{ add 10 5 }}</p>              <!-- 15 -->
<p>Difference: {{ sub 20 8 }}</p>         <!-- 12 -->
<p>Product: {{ mul 6 7 }}</p>             <!-- 42 -->
<p>Division: {{ div 100 4 }}</p>          <!-- 25 -->
<p>Remainder: {{ mod 17 5 }}</p>          <!-- 2 -->

<!-- Advanced math -->
<p>Absolute: {{ abs -15 }}</p>            <!-- 15 -->
<p>Minimum: {{ min 3 7 }}</p>             <!-- 3 -->
<p>Maximum: {{ max 3 7 }}</p>             <!-- 7 -->

<!-- Reading time calculation -->
<p>{{ div page.word_count 200 }} min read</p>
```

## Time Functions

Handle dates and times:

```html
<!-- Current time -->
<p>Built on: {{ now }}</p>

<!-- Date formatting -->
<time>{{ dateFormat "%B %d, %Y" page.date }}</time>
<span>{{ dateFormat "%Y-%m-%d" now }}</span>

<!-- Duration -->
{{ $reading_time := duration page.reading_time }}
```

## Comparison Functions

Build conditional logic:

```html
<!-- Equality checks -->
{{ if eq page.type "post" }}
  <span class="post-badge">Blog Post</span>
{{ end }}

{{ if ne page.draft true }}
  <p>Published content</p>
{{ end }}

<!-- Numeric comparisons -->
{{ if gt page.word_count 1000 }}
  <span class="long-read">Long Read</span>
{{ end }}

{{ if le page.reading_time 5 }}
  <span class="quick-read">Quick Read</span>
{{ end }}

<!-- Logical operations -->
{{ if and (eq page.type "post") (gt page.word_count 500) }}
  <span class="substantial-post">In-depth Article</span>
{{ end }}
```

## Crypto Functions

Generate hashes for cache-busting or IDs:

```html
<!-- Content hashing -->
<link rel="stylesheet" href="/style.css?v={{ md5 page.content }}">

<!-- Unique IDs -->
<div id="section-{{ sha1 page.title }}">
  {{ page.content }}
</div>

<!-- Secure hashing -->
<meta name="content-hash" content="{{ sha256 page.content }}">
```

## URL Functions

Handle URLs and links:

```html
<!-- Absolute URLs -->
<link rel="canonical" href="{{ absURL page.url site.baseurl }}">

<!-- Relative URLs -->
<a href="{{ relURL "/about" }}">About</a>

<!-- URL-safe strings -->
<a href="/tags/{{ urlize tag }}">{{ tag }}</a>
```

## Type Conversion Functions

Convert between data types:

```html
<!-- String conversion -->
<span data-count="{{ string page.word_count }}">Articles</span>

<!-- Integer conversion -->
{{ $year := int "2025" }}

<!-- Float conversion -->
{{ $rating := float "4.5" }}
```

## Practical Examples

### Dynamic Navigation with Functions

```html
<nav>
  {{ for page in site.regular_pages }}
    {{ if and (ne page.url "/") (not page.draft) }}
      <a href="{{ page.url }}"
         class="nav-link {{ if eq page.url $.page.url }}active{{ end }}">
        {{ title page.title }}
      </a>
    {{ end }}
  {{ endfor }}
</nav>
```

### Tag Cloud with Styling

```html
<div class="tag-cloud">
  {{ range $tag, $pages := site.tags }}
    {{ $count := len $pages }}
    {{ $size := add (mul $count 2) 12 }}
    <a href="/tags/{{ urlize $tag }}"
       style="font-size: {{ $size }}px"
       title="{{ $count }} posts">
      {{ title $tag }}
    </a>
  {{ end }}
</div>
```

### Reading Time with Icons

```html
<div class="reading-time">
  {{ $time := page.reading_time }}
  {{ if le $time 3 }}
    ⚡ {{ $time }} min read
  {{ else if le $time 10 }}
    📖 {{ $time }} min read
  {{ else }}
    📚 {{ $time }} min read
  {{ end }}
</div>
```

## Function Chaining

Combine functions for powerful transformations:

```html
<!-- Complex string processing -->
<h2 id="{{ urlize (lower page.title) }}">
  {{ title (truncate page.title 50) }}
</h2>

<!-- Mathematical operations -->
<div class="progress" style="width: {{ mul (div page.word_count 2000) 100 }}%">
</div>

<!-- Content analysis -->
{{ if gt (len (split page.content " ")) 500 }}
  <span class="long-form">Long-form content</span>
{{ end }}
```

## Performance Tips

1. **Cache expensive operations**: Store results in variables
2. **Use specific functions**: `len` is faster than `count`
3. **Avoid nested loops**: Pre-process data when possible
4. **Combine operations**: Chain functions instead of multiple steps

```html
<!-- Good: Cache the result -->
{{ $word_count := page.word_count }}
{{ $reading_time := div $word_count 200 }}

<!-- Good: Chain operations -->
{{ $slug := urlize (lower page.title) }}
```

Functions make Lapis templates incredibly powerful while keeping them readable and maintainable. The established API ensures easy migration, while the intuitive syntax makes them accessible to all developers.