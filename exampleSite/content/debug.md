---
title: "Template Debug & Validation"
layout: "page"
description: "Debug page to validate template engine functionality"
toc: false
---

# Template Engine Debug & Validation

This page validates that the template engine is correctly processing site variables and loops.

## Site Information

**Site Title:** {{ site.title }}
**Base URL:** {{ site.base_url }}
**Total Pages:** {{ len site.pages }}
**Regular Pages Count:** {{ len site.regular_pages }}

## Regular Pages List

{{ range site.regular_pages }}
- **{{ .title }}** → [{{ .url }}]({{ .url }}) (Draft: {{ .draft }})
{{ end }}

## All Pages Debug

Total site pages: {{ len site.pages }}

{{ range site.pages }}
- **{{ .title }}** → [{{ .url }}]({{ .url }}) (Kind: {{ .kind }}, Section: {{ .section }})
{{ end }}

## Site Statistics

- **Pages:** {{ len site.pages }}
- **Regular Pages:** {{ len site.regular_pages }}
- **Theme:** {{ site.theme }}
- **Output Dir:** {{ site.output_dir }}

## Template Processing Test

Current page info:
- **Title:** {{ page.title }}
- **URL:** {{ page.url }}
- **Layout:** {{ page.layout }}
- **File Path:** {{ page.file_path }}

---

*This debug page helps validate that the template engine is correctly processing site.regular_pages and other template variables.*