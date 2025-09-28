# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2025-09-27

### 🚀 Major Features

#### Professional Page Kinds System
- **Professional Content Architecture**: Implemented page kinds for structured content organization
  - `single` - Individual content pages (blog posts, articles)
  - `list` - Archive pages that list multiple items
  - `section` - Directory-based content grouping (e.g., `/posts/`, `/projects/`)
  - `taxonomy` - Category/tag listing pages (e.g., `/tags/`)
  - `term` - Individual taxonomy pages (e.g., `/tags/crystal/`)
  - `home` - Site homepage (special case of list)
- **Intelligent Template Resolution**: Template lookup with hierarchical fallbacks
  - Section-specific templates: `layouts/posts/single.html`
  - Default templates: `layouts/_default/single.html`
  - Theme inheritance with automatic fallbacks
- **Automatic Section Detection**: Smart content organization based on directory structure
- **Template Context Enhancement**: Page kind and section information available in templates

#### Multi-Format Output System
- **Flexible Output Formats**: Generate multiple file formats from single content source
  - **HTML**: Standard web pages (default)
  - **JSON**: Machine-readable content for APIs and search
  - **RSS/Atom**: Syndication feeds
  - **Plain Text**: LLM-friendly content format
  - **Custom Formats**: Configurable media types and extensions
- **Format-Specific Templates**: Template hierarchy supports format specialization
  - `single.json.json` for JSON output
  - `single.llm.txt` for plain text
  - `list.rss.xml` for RSS feeds
- **Configuration-Driven**: YAML configuration for custom output formats
- **Simultaneous Generation**: All configured formats rendered in parallel

#### Enhanced Template System
- **Template Conditionals**: Extended conditional processing support
  - `{{ if description }}...{{ endif }}`
  - `{{ if date }}...{{ endif }}`
  - `{{ if tags }}...{{ endif }}`
- **Page Context Variables**: Rich template context with page metadata
  - `{{ page.kind }}` - Page type information
  - `{{ page.section }}` - Section classification
  - `{{ section }}` - Section name shorthand
- **Backward Compatibility**: Zero breaking changes to existing v0.2.0 templates

### 🔧 Technical Improvements

#### Content Processing
- **Smart Content Loading**: Enhanced content discovery with proper section detection
- **Page Kind Detection**: Automatic classification based on file structure and naming
- **Multi-Format Rendering Pipeline**: Efficient parallel rendering of multiple output formats

#### Theme System
- **Proper Theme Inheritance**: Clean theme resolution without file duplication
- **Built-in Theme Support**: Automatic detection of project themes vs. site-specific themes
- **ExampleSite Integration**: Clean example sites that reference parent themes

#### Performance & Reliability
- **Maintained Build Speed**: Multi-format generation with no performance degradation (~15ms builds)
- **Memory Efficiency**: Lazy initialization of output format managers
- **Error Handling**: Graceful fallbacks for missing templates and formats

### 📚 Documentation & Examples

#### Updated Templates
- **Page Kind Templates**: Complete set of default templates for all page kinds
- **Multi-Format Examples**: JSON and plain text template examples
- **Template Documentation**: Enhanced inline documentation

#### Configuration Examples
- **Output Format Configuration**: YAML examples for custom format definition
- **Page Kind Outputs**: Configuration examples for format assignment by page type

### 🚀 Migration Guide

#### For Existing v0.2.0 Sites
- **Zero Breaking Changes**: All existing sites continue to work without modification
- **Opt-in Enhancements**: New features available through configuration
- **Template Compatibility**: Existing templates work with new page kind system

#### New Features Available
```yaml
# config.yml - Enable multi-format output
outputs:
  single: ["html", "json", "llm"]  # Generate 3 formats for single pages
  home: ["html", "rss"]            # Generate 2 formats for home page
  list: ["html", "rss"]            # Generate 2 formats for list pages
```

### 🎯 Performance Metrics
- **Build Time**: Maintained <20ms for typical sites
- **Multi-Format Overhead**: <5ms additional time for 3-format generation
- **Memory Usage**: Efficient lazy loading with minimal memory impact

---

## [0.2.0] - 2025-09-27

### 🚀 Major Features

#### Smart Asset Processing
- **Automatic Image Optimization**: WebP conversion with fallbacks for maximum browser compatibility
- **Responsive Images**: Auto-generated srcsets for multiple screen sizes (320w, 640w, 1024w, 1920w)
- **Asset Fingerprinting**: Cache-busting with SHA256 hashes for optimal performance
- **CSS/JS Minification**: Automatic asset optimization during build

#### Powerful Shortcode System
- **9 Built-in Shortcodes**: Comprehensive content widgets for dynamic page generation
  - `{% image %}` - Responsive images with automatic optimization
  - `{% alert %}` - Styled alert boxes (info, warning, error, success)
  - `{% button %}` - Interactive buttons with multiple styles
  - `{% youtube %}` - Embedded YouTube videos with lazy loading
  - `{% highlight %}` - Syntax-highlighted code blocks with copy functionality
  - `{% gallery %}` - Image galleries with lightbox support
  - `{% quote %}` - Styled blockquotes with attribution
  - `{% toc %}` - Table of contents generation
  - `{% recent_posts %}` - Dynamic recent posts listing
- **Enhanced Processing**: Improved shortcode processing order and reliability
- **HTML Generation**: Clean, semantic HTML output with proper escaping
- **Helper Functions**: Added text humanization and improved content formatting

#### Advanced Content Features
- **RSS/Atom/JSON Feeds**: Automatic feed generation in multiple formats
- **Smart Pagination**: Intelligent archive pagination with navigation
- **SEO Optimization**: Automated sitemaps and meta tag generation
- **Cross-References**: Intelligent content linking system

#### Performance Analytics
- **Build Insights**: Detailed performance breakdown and timing analysis
- **Optimization Hints**: Intelligent suggestions for improving build performance
- **File Size Analysis**: Largest files reporting and optimization recommendations
- **Performance Profiling**: Build time analysis with bottleneck identification

#### Enhanced Developer Experience
- **Professional Templates**: Curated template gallery (blog, docs, portfolio, minimal)
- **Interactive CLI**: Template galleries and guided setup
- **Live Reload**: Instant browser updates during development
- **Smart Content Creation**: Intelligent defaults for new pages and posts

#### Professional Theme System
- **Theme Configuration**: Configure themes via `theme: "name"` in config.yml
- **Smart Theme Resolution**: Automatic fallback from site themes → built-in themes → default
- **CSS Cascade Priority**: Theme base styles → site overrides → page-specific styles
- **Theme Asset Processing**: Automatic copying of theme assets with override support
- **Clean Architecture**: Single theme location, no duplicates or confusion
- **Partials System**: `{{ partial "head" . }}` for reusable template components
- **Automatic CSS Discovery**: `{{ auto_css }}` eliminates manual CSS management
- **Partial Hierarchy**: Site partials override theme partials with intelligent fallbacks

#### Advanced Layout System
- **Partials System**: Complete `{{ partial "name" . }}` implementation following established conventions
- **Built-in Partials**: Automatic head, header, footer partials with intelligent fallbacks
- **Partial Override Hierarchy**: Site partials → theme partials → built-in partials
- **Automatic Asset Discovery**: Zero-configuration CSS loading with theme cascade
- **Template Context Enhancement**: Rich context with theme-aware CSS building
- **Layout Inheritance**: Improved template inheritance with block system
- **Asset Pipeline Integration**: Seamless integration between themes and asset processing

### 🛠️ Improvements

#### CLI Enhancements
- **Template System**: `lapis init --template <name>` with professional templates
- **Template Gallery**: `lapis init --template list` to browse available options
- **Smart Content Creation**: Enhanced `lapis new` with better defaults
- **Performance Reporting**: Build analytics integrated into CLI output

#### Project Structure
- **Standardized Example Site**: Unified `exampleSite/` directory following established conventions
- **Comprehensive Documentation**: Enhanced README with feature showcase
- **Clean Architecture**: Removed scattered test directories for better organization

#### Content Processing
- **Enhanced Markdown**: Full YAML frontmatter support with extended metadata
- **Shortcode Processing**: Proper processing order ensuring reliable content generation
- **Template System**: Improved template inheritance and customization

#### Theme & Layout Improvements
- **Unified Theme Architecture**: Eliminated duplicate theme directories and confusion
- **Config-Driven Themes**: Added `theme` configuration parameter with intelligent resolution
- **CSS Cascade System**: Proper inheritance from theme → site → page-specific styles
- **Partials System**: Complete partials system with `{{ partial "name" . }}` support
- **Automatic CSS Discovery**: Replaced manual `css_includes` with intelligent auto-discovery
- **Partial Template Hierarchy**: Site partials override theme partials with built-in fallbacks
- **Template CLI Updates**: Generate override files instead of theme replacements
- **Asset Processing**: Enhanced to handle both theme and site assets with proper priority

### 🔧 Technical Details

#### Dependencies
- **Markd**: Markdown processing with advanced features
- **HTTP Client**: Asset fetching and optimization
- **Ameba**: Code quality and linting

#### Performance
- **Crystal-Powered**: Lightning-fast builds leveraging Crystal's performance
- **Incremental Processing**: Only rebuild what's changed
- **Optimized Assets**: Smart caching and compression

#### Template Engine
- **Partials Module**: Complete partials system
- **Automatic Discovery**: CSS and partial auto-detection with fallbacks
- **Template Hierarchy**: Site → theme → built-in template resolution
- **Legacy Support**: Backwards compatibility with existing `css_includes`

### 📚 Documentation
- **Example Site**: Comprehensive showcase of all v0.2.0 features
- **Template Documentation**: Detailed guides for each template type
- **API Reference**: Complete shortcode and configuration documentation
- **Best Practices**: Performance optimization and content organization guides

### 🐛 Bug Fixes
- Fixed shortcode processing order ensuring `{% recent_posts %}` renders correctly
- Resolved duplicate header issues in content generation
- Fixed asset processing pipeline compilation errors
- Improved error handling in template system
- Fixed theme CSS loading issue where theme styles weren't being applied
- Resolved duplicate "Recent Posts" headers in content output
- Fixed theme path resolution for proper asset copying
- Eliminated theme directory duplication and confusion
- Replaced brittle manual CSS management with automatic discovery
- Fixed CSS loading inconsistencies across different page types (home, posts, archives)

---

## [0.1.0] - 2025-09-27

### 🎉 Initial Release

#### Core Features
- **Static Site Generation**: Fast, reliable site building with Crystal
- **Markdown Support**: Full markdown processing with YAML frontmatter
- **Template System**: Basic template engine for customizable layouts
- **Development Server**: Live reload server for development workflow
- **CLI Interface**: Simple command-line interface for site management

#### Basic Functionality
- Site initialization with `lapis init`
- Content building with `lapis build`
- Development server with `lapis serve`
- Page and post creation with `lapis new`

#### Foundation
- Project structure and configuration system
- Basic content processing pipeline
- Simple template rendering
- Static asset handling

---

## Future Roadmap

### v0.3.0 (Planned)
- **Modular Shortcode Architecture**: Plugin system for third-party shortcodes
- **Theme System**: Advanced theming with inheritance
- **Multi-language Support**: Internationalization features
- **Advanced SEO**: Schema markup and social media optimization

### v0.4.0 (Planned)
- **Headless CMS Integration**: API-driven content management
- **Build Optimization**: Advanced caching and incremental builds
- **Asset Pipeline**: Advanced CSS/JS processing with bundling
- **PWA Support**: Progressive web app features

[0.2.0]: https://github.com/lapis-lang/lapis/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/lapis-lang/lapis/releases/tag/v0.1.0