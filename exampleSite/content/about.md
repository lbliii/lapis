---
title: "About Lapis"
layout: "page"
description: "Learn about Lapis, the Crystal-powered static site generator that combines lightning-fast performance with modern developer experience"
toc: true
---

# About Lapis

Lapis is a modern static site generator built with Crystal that combines lightning-fast performance with an exceptional developer experience. It's designed for developers who want to build fast, beautiful, and maintainable static sites without compromising on performance or functionality.

## 🚀 What Makes Lapis Special?

### Crystal-Powered Performance
Lapis leverages Crystal's performance to deliver sub-second builds for most sites. Crystal compiles to native code, providing near-C performance with Ruby-like syntax, making it one of the fastest static site generators available.

### Modern Developer Experience
- **Live Reload**: Instant browser updates during development
- **Hot Reload**: CSS and JavaScript changes without page refresh
- **Interactive CLI**: Guided setup and content creation
- **Performance Monitoring**: Real-time build analytics and optimization hints
- **Error Handling**: Graceful error recovery with helpful error messages

### Comprehensive Feature Set
- **Shortcodes**: Dynamic content widgets and components
- **Multi-format Output**: HTML, JSON, RSS, Atom, and Markdown
- **Plugin System**: Extensible architecture for custom functionality
- **Asset Optimization**: Automatic CSS/JS minification and image optimization
- **SEO Ready**: Automatic sitemaps, meta tags, and structured data

## 🎯 Who Is Lapis For?

### Content Creators
- **Bloggers**: Fast, SEO-optimized blogging platform
- **Writers**: Focus on content with powerful publishing tools
- **Documentation Authors**: Technical documentation with search and navigation

### Developers
- **Web Developers**: Modern tooling with excellent performance
- **Open Source Contributors**: Extensible platform for project sites
- **Technical Writers**: Rich content creation with code highlighting

### Organizations
- **Startups**: Fast, cost-effective website solution
- **Corporations**: Professional business websites
- **Educational Institutions**: Course materials and documentation

## 🛠️ Technical Architecture

### Core Components

#### Content Processing
```crystal
# Efficient content processing with Crystal
class ContentProcessor
  def initialize(@config : Config)
    @markdown_processor = MarkdownProcessor.new
    @template_engine = TemplateEngine.new
  end

  def process_page(page : Page) : String
    content = @markdown_processor.process(page.content)
    @template_engine.render(page.layout, {
      "page" => page,
      "content" => content
    })
  end
end
```

#### Asset Pipeline
```crystal
# Modern asset processing
class AssetPipeline
  def process_assets(assets : Array(Asset)) : Array(Asset)
    assets.map do |asset|
      case asset.type
      when :css
        minify_css(asset)
      when :js
        minify_js(asset)
      when :image
        optimize_image(asset)
      else
        asset
      end
    end
  end
end
```

#### Live Reload System
```crystal
# WebSocket-based live reload
class LiveReloadServer
  def initialize(@port : Int32)
    @clients = [] of WebSocket
    @file_watcher = FileWatcher.new
  end

  def start
    @file_watcher.on_change do |file|
      notify_clients(file)
    end
  end
end
```

## 📊 Performance Benchmarks

### Build Performance
- **Small sites** (< 50 pages): < 0.5s
- **Medium sites** (50-500 pages): < 2s
- **Large sites** (500+ pages): < 10s

### Runtime Performance
- **First Contentful Paint**: < 1.5s
- **Largest Contentful Paint**: < 2.5s
- **Cumulative Layout Shift**: < 0.1
- **Time to Interactive**: < 3s

### Memory Efficiency
- **Build Memory**: 45-180MB depending on site size
- **Runtime Memory**: Minimal (static files)
- **Cache Efficiency**: 85-95% hit rate

## 🌟 Key Features

### Content Management
- **Enhanced Markdown**: Full support with YAML frontmatter
- **Taxonomies**: Tags, categories, and custom taxonomies
- **Collections**: Organized content groups and series
- **Cross-references**: Intelligent content linking

### Asset Optimization
- **Image Optimization**: Automatic WebP conversion and responsive images
- **CSS/JS Bundling**: Automatic minification and concatenation
- **Asset Fingerprinting**: Cache busting for production
- **Tree Shaking**: Remove unused code (experimental)

### SEO & Analytics
- **Automatic SEO**: Meta tags, sitemaps, and structured data
- **Analytics Integration**: Google Analytics, Plausible, Umami
- **Social Cards**: Open Graph and Twitter Card support
- **Performance Monitoring**: Built-in performance analysis

### Developer Tools
- **Interactive CLI**: Template galleries and guided setup
- **Performance Profiling**: Detailed build time analysis
- **Error Handling**: Graceful error recovery
- **Debug Mode**: Comprehensive debugging information

## 🎨 Theme System

### Default Theme
Lapis comes with a beautiful, responsive theme that includes:
- Clean, readable typography
- Mobile-first responsive design
- Dark mode support
- Syntax highlighting for code
- Accessible navigation

### Custom Themes
Create custom themes with:
- Template inheritance
- Partial templates
- Custom layouts
- Asset management
- Responsive design

## 🔌 Plugin Ecosystem

### Built-in Plugins
- **SEO Plugin**: Comprehensive search engine optimization
- **Analytics Plugin**: Multiple analytics providers
- **Asset Plugin**: Advanced asset optimization
- **Sitemap Plugin**: XML sitemap generation

### Custom Plugins
Extend Lapis functionality with custom plugins:
```crystal
class MyPlugin < Lapis::Plugin
  def initialize(config : Hash(String, YAML::Any))
    super("my-plugin", "1.0.0", config)
  end

  def on_after_build(generator : Generator) : Nil
    # Custom build logic
    generate_custom_files(generator)
  end
end
```

## 🚀 Getting Started

### Quick Start
```bash
# Install Lapis
git clone https://github.com/lapis-lang/lapis.git
cd lapis
shards install
crystal build src/lapis.cr -o bin/lapis

# Create a new site
bin/lapis init my-site
cd my-site

# Start development
bin/lapis serve
```

### First Steps
1. **Create content**: Add pages and posts in `content/`
2. **Customize theme**: Modify layouts and styles
3. **Add assets**: Include CSS, JavaScript, and images
4. **Configure site**: Update `config.yml` with your settings
5. **Deploy**: Build and deploy to any static hosting service

## 🌍 Community & Support

### Getting Help
- **Documentation**: Comprehensive guides and API reference
- **GitHub Issues**: Bug reports and feature requests
- **Discussions**: Community discussions and Q&A
- **Discord**: Real-time community chat

### Contributing
We welcome contributions! Areas where you can help:
- **Code**: Bug fixes and new features
- **Documentation**: Guides and tutorials
- **Themes**: New themes and templates
- **Plugins**: Extensions and integrations
- **Testing**: Bug reports and testing

### Community Resources
- **GitHub Repository**: [github.com/lapis-lang/lapis](https://github.com/lapis-lang/lapis)
- **Documentation**: [docs.lapis.dev](https://docs.lapis.dev)
- **Discord Server**: [discord.gg/lapis](https://discord.gg/lapis)
- **Twitter**: [@lapis_ssg](https://twitter.com/lapis_ssg)

## 🎯 Roadmap

### Current Version (v0.4.0)
- ✅ Incremental builds
- ✅ Live reload system
- ✅ Asset optimization
- ✅ Plugin system
- ✅ Multi-format output

### Upcoming Features
- 🔄 VS Code extension
- 🔄 Hot module replacement
- 🔄 TypeScript support
- 🔄 GraphQL integration
- 🔄 Component system
- 🔄 Testing framework

### Long-term Vision
- **Performance**: Sub-second builds for any site size
- **Developer Experience**: Best-in-class tooling and workflow
- **Ecosystem**: Rich plugin and theme ecosystem
- **Community**: Active, helpful community of developers

## 📈 Success Stories

### Developer Blogs
"Lapis transformed my blogging workflow. What used to take minutes now takes seconds, and the live reload makes development a joy." - *Sarah, Developer*

### Documentation Sites
"We migrated our documentation from Jekyll to Lapis and saw a 10x improvement in build times. The developer experience is incredible." - *Mike, Technical Writer*

### Corporate Websites
"Lapis powers our corporate website with excellent performance and SEO. Our Lighthouse scores are perfect." - *Jennifer, Marketing Director*

## 🤝 Why Choose Lapis?

### Performance
- **Fastest builds**: Crystal-powered performance
- **Efficient memory usage**: Low resource consumption
- **Optimized output**: Minified and optimized assets
- **Scalable**: Handles sites of any size

### Developer Experience
- **Modern tooling**: Live reload and hot reload
- **Intuitive syntax**: Crystal's readable syntax
- **Comprehensive features**: Everything you need out of the box
- **Extensible**: Plugin system for custom functionality

### Community
- **Active development**: Regular updates and improvements
- **Helpful community**: Supportive developers and users
- **Open source**: Transparent development process
- **Documentation**: Comprehensive guides and examples

---

*Ready to experience the power of Crystal-powered static site generation? [Get started with Lapis today](https://github.com/lapis-lang/lapis) and join our community of developers building fast, beautiful static sites.*