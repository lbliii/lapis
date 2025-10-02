# Shortcode Processing Fix - Hugo's Dual Approach

## Problem

Currently, ALL shortcodes return raw HTML that's injected BEFORE markdown processing:
```
Markdown → Shortcode (returns HTML) → Mix of MD+HTML → Markd → Crashes
```

This breaks markdown context and causes Markd to fail on large files.

## Solution: Hugo's Dual Syntax

Hugo has two shortcode types:

### 1. `{{< >}}` - Raw HTML (Post-Markdown)
```markdown
Some **markdown** here

{{< youtube "abc123" >}}

More _markdown_ here
```

Process: `Markdown → Markd → HTML → Inject shortcodes → Final HTML`

### 2. `{{%  %}}` - Markdown Content (Pre-Markdown)
```markdown
Some **markdown** here

{{%alert "info" %}}
This content **supports markdown** and will be _processed_.
{{%endalert %}}

More _markdown_ here
```

Process: `Markdown + Shortcode expansion → Combined Markdown → Markd → HTML`

---

## Implementation Plan

### Phase 1: Change Current Syntax to `{{< >}}`

**Current**: `{% alert "info" %}` returns `<div>...</div>` BEFORE markdown  
**New**: `{{< alert "info" >}}` returns `<div>...</div>` AFTER markdown

```crystal
# src/lapis/content.cr
private def process_markdown(markdown : String, config : Config) : String
  # Step 1: Process {{%  %}} markdown shortcodes (expand to markdown)
  markdown_with_expansions = process_markdown_shortcodes(markdown)
  
  # Step 2: Convert to HTML
  html = Markd.to_html(markdown_with_expansions, options)
  
  # Step 3: Process {{< >}} HTML shortcodes (inject HTML)
  final_html = process_html_shortcodes(html, config)
  
  final_html
end
```

### Phase 2: Implement Two Processors

```crystal
# src/lapis/shortcodes.cr
module Lapis
  class ShortcodeProcessor
    # Process {{< >}} - returns HTML, injected AFTER markdown
    def process_html_shortcodes(html : String) : String
      result = html
      
      # These return HTML and are safe AFTER markdown processing
      result = result.gsub(/\{\{<\s*youtube\s+"([^"]+)"\s*>\}\}/) do
        generate_youtube_embed($1)
      end
      
      result = result.gsub(/\{\{<\s*image\s+"([^"]+)"\s+"([^"]*)"\s*>\}\}/) do
        generate_responsive_image($1, $2)
      end
      
      # ... other HTML shortcodes
      result
    end
    
    # Process {{%  %}} - returns markdown, processed WITH content
    def process_markdown_shortcodes(markdown : String) : String
      result = markdown
      
      # Alert as markdown block
      result = result.gsub(/\{\{%\s*alert\s+"([^"]+)"\s*%\}\}(.*?)\{\{%\s*endalert\s*%\}\}/m) do
        alert_type = $1
        content = $2.strip
        generate_alert_markdown(content, alert_type)
      end
      
      # Quote as markdown blockquote
      result = result.gsub(/\{\{%\s*quote\s+"([^"]*)"\s+"([^"]*)"\s*%\}\}(.*?)\{\{%\s*endquote\s*%\}\}/m) do
        author = $1
        source = $2
        quote_text = $3.strip
        generate_quote_markdown(quote_text, author, source)
      end
      
      result
    end
    
    private def generate_alert_markdown(content : String, type : String) : String
      # Return markdown that will be processed by Markd
      icon = case type
             when "info" then "ℹ️"
             when "success" then "✅"
             when "warning" then "⚠️"
             when "error" then "🚨"
             else "📝"
             end
      
      # Use HTML comment markers that Markd preserves
      <<-MD
      
      <!-- alert-start:#{type} -->
      #{icon} **#{type.capitalize}**
      
      #{content}
      <!-- alert-end -->
      
      MD
    end
    
    private def generate_quote_markdown(text : String, author : String, source : String) : String
      # Return as markdown blockquote
      <<-MD
      
      > #{text}
      >
      > — **#{author}**#{source.empty? ? "" : ", _#{source}_"}
      
      MD
    end
  end
end
```

---

## Benefits

### ✅ **Fixes the Crash**
- No more HTML injection breaking markdown context
- Markd only sees pure markdown or pure HTML

### ✅ **More Powerful**
- `{{%  %}}` shortcodes can contain **markdown**
- Useful for alerts, callouts, notes with formatted content

### ✅ **Better Performance**
- HTML shortcodes only process final HTML (one pass)
- Markdown shortcodes expand before parsing (no double processing)

### ✅ **Familiar to Users**
- Same as Hugo (users already know this)
- Clear distinction between HTML and markdown content

---

## Migration Path

### v0.4.1 (Current)
- Document limitation
- Keep current `{% %}` syntax working

### v0.5.0 (Refactor)
- Add `{{< >}}` for HTML shortcodes
- Add `{{%  %}}` for markdown shortcodes
- Deprecate `{% %}` with migration guide
- Process in correct order

### v0.6.0
- Remove `{% %}` support

---

## Example: Before vs After

### Before (Broken)
```markdown
## Features

- Fast builds
- Easy setup
{% alert "info" %}This is important{% endalert %}  ← Injects <div> breaking list
- Great performance
```

Markd sees:
```
## Features

- Fast builds
- Easy setup
<div class="alert">This is important</div>  ← List context BROKEN
- Great performance  ← Not parsed as list item!
```

### After (Fixed)

**Option 1: HTML shortcode (post-markdown)**
```markdown
## Features

- Fast builds
- Easy setup

{{< alert "info" >}}This is important{{< /alert >}}

- Great performance
```

Markd sees pure markdown, HTML injected after.

**Option 2: Markdown shortcode (pre-markdown)**
```markdown
## Features

- Fast builds
- Easy setup

{{%alert "info" %}}
This **supports** _markdown_!
{{%endalert %}}

- Great performance
```

Expands to pure markdown before Markd sees it.

---

## Testing Strategy

```crystal
describe ShortcodeProcessor do
  it "processes HTML shortcodes after markdown" do
    input = "Some **bold** text\n\n{{< youtube \"abc\" >}}\n\nMore text"
    
    # Step 1: Markdown
    html = Markd.to_html(input)
    # Step 2: HTML shortcodes
    final = processor.process_html_shortcodes(html)
    
    final.should contain("<strong>bold</strong>")
    final.should contain("<iframe")
  end
  
  it "processes markdown shortcodes before markdown" do
    input = "{{%alert \"info\" %}}Some **bold** alert{{%endalert %}}"
    
    # Step 1: Expand shortcode
    expanded = processor.process_markdown_shortcodes(input)
    # Step 2: Process markdown
    html = Markd.to_html(expanded)
    
    html.should contain("<strong>bold</strong>")
  end
end
```

---

## Backward Compatibility

Keep `{% %}` working in v0.4.x and v0.5.x with deprecation warning:

```crystal
def process(content : String) : String
  if content.includes?("{%")
    Logger.warn("Deprecated: {% %} syntax is deprecated. Use {{< >}} for HTML or {{%  %}} for markdown.")
  end
  
  # Support old syntax
  result = process_legacy_shortcodes(content)
  # Support new syntax
  result = process_markdown_shortcodes(result)
  result
end
```

---

**This fixes the root cause AND makes Lapis more powerful!**

