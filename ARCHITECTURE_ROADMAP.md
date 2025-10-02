# Architecture Roadmap - Lapis v0.5.0 and Beyond

> **Note**: This is the refactoring plan. Current v0.4.0 works fine - don't refactor until we have real user feedback!

**Created**: October 2, 2025  
**Target**: v0.5.0 (1-2 months)  
**Estimated Effort**: 2-3 weeks of focused work

---

## 📊 Current State Analysis

### **What Works**
- ✅ Builds sites successfully
- ✅ 490/490 unit tests passing
- ✅ Template engine functional
- ✅ Asset processing works
- ✅ Good feature set

### **What's Problematic**
- ❌ Circular dependencies (Generator ↔ TemplateEngine ↔ FunctionProcessor)
- ❌ Multiple wrappers for same data (Content → Page → Site → Query)
- ❌ God object (Generator: 1000+ lines, 20+ responsibilities)
- ❌ Unclear data flow (bidirectional, hard to trace)
- ❌ Performance issues (O(n²) patterns, still has GC pressure)
- ❌ Hard to test (requires complex mocks)

---

## 🎯 Architecture Goals for v0.5.0

### **Core Principles**

1. **Unidirectional Data Flow**
   - Data flows in ONE direction: Load → Process → Build → Render → Write
   - No backward references, no circular dependencies

2. **Single Responsibility**
   - Each class does ONE thing well
   - Generator becomes a coordinator, not a doer

3. **Immutability Where Possible**
   - Site model is immutable after building
   - Content is immutable after processing
   - Fewer bugs, easier parallelization

4. **Clear Ownership**
   - Every object has ONE owner
   - Lifetimes are obvious
   - No "who manages this?" confusion

5. **Test-Friendly**
   - Pure functions where possible
   - Easy to test in isolation
   - No need for complex mocks

---

## 🏗️ Proposed Architecture

### **The Pipeline Pattern**

```
┌─────────────────────────────────────────────────────────────┐
│                      BUILD PIPELINE                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Stage 1: LOAD                                              │
│  ┌──────────────┐                                           │
│  │ ContentLoader│ → Array(RawContent)                       │
│  └──────────────┘   (frontmatter + markdown string)        │
│         ↓                                                    │
│  Stage 2: PROCESS                                           │
│  ┌─────────────────┐                                        │
│  │ContentProcessor │ → Array(ProcessedContent)             │
│  └─────────────────┘   (HTML, metadata extracted)          │
│         ↓                                                    │
│  Stage 3: BUILD MODEL                                       │
│  ┌─────────────┐                                            │
│  │ SiteBuilder │ → Site (immutable model)                   │
│  └─────────────┘   (all pages, organized)                  │
│         ↓                                                    │
│  Stage 4: RENDER                                            │
│  ┌──────────┐                                               │
│  │ Renderer │ → Array(RenderedPage)                         │
│  └──────────┘   (HTML with templates applied)              │
│         ↓                                                    │
│  Stage 5: WRITE                                             │
│  ┌────────────┐                                             │
│  │ FileWriter │ → Disk                                      │
│  └────────────┘   (output directory)                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 New Module Structure

### **Core Data Models** (Simple, Immutable)

```crystal
module Lapis::Models
  # Raw content straight from disk
  struct RawContent
    property path : String
    property frontmatter : Hash(String, YAML::Any)
    property markdown : String
  end
  
  # Processed content ready for rendering
  struct ProcessedContent
    property metadata : Metadata
    property html : String
    property url : String
    property kind : PageKind
    property section : String
  end
  
  # Metadata extracted from frontmatter
  struct Metadata
    property title : String
    property date : Time?
    property tags : Array(String)
    property categories : Array(String)
    property description : String?
    property draft : Bool
    # ... other fields
  end
  
  # Immutable site model
  struct Site
    property pages : Array(ProcessedContent)
    property config : Config
    property sections : Hash(String, Array(ProcessedContent))
    property taxonomies : Hash(String, Hash(String, Array(ProcessedContent)))
    
    # Query methods (no mutation!)
    def recent_posts(n : Int32) : Array(ProcessedContent)
    def by_section(name : String) : Array(ProcessedContent)
    def by_tag(tag : String) : Array(ProcessedContent)
  end
  
  # Rendered page ready to write
  struct RenderedPage
    property html : String
    property path : String
    property metadata : Metadata
  end
end
```

---

## 🔧 Pipeline Components

### **Stage 1: Content Loader**

```crystal
module Lapis::Pipeline
  class ContentLoader
    def initialize(@config : Config)
    end
    
    def load_all : Array(Models::RawContent)
      Dir.glob("#{@config.content_dir}/**/*.md").map do |path|
        load_file(path)
      end
    end
    
    private def load_file(path : String) : Models::RawContent
      content = File.read(path)
      frontmatter, markdown = parse_frontmatter(content)
      Models::RawContent.new(path, frontmatter, markdown)
    end
  end
end
```

### **Stage 2: Content Processor**

```crystal
module Lapis::Pipeline
  class ContentProcessor
    def initialize(@config : Config)
      @markdown_processor = MarkdownProcessor.new
      @shortcode_processor = ShortcodeProcessor.new(@config)
    end
    
    def process_all(raw : Array(Models::RawContent)) : Array(Models::ProcessedContent)
      raw.map { |r| process_one(r) }
    end
    
    private def process_one(raw : Models::RawContent) : Models::ProcessedContent
      # 1. Extract metadata
      metadata = Metadata.from_frontmatter(raw.frontmatter)
      
      # 2. Process shortcodes
      markdown = @shortcode_processor.process(raw.markdown)
      
      # 3. Convert to HTML
      html = @markdown_processor.to_html(markdown)
      
      # 4. Generate URL
      url = URLGenerator.generate(raw.path, metadata)
      
      # 5. Detect page kind
      kind = PageKindDetector.detect(raw.path)
      
      Models::ProcessedContent.new(metadata, html, url, kind, ...)
    end
  end
end
```

### **Stage 3: Site Builder**

```crystal
module Lapis::Pipeline
  class SiteBuilder
    def initialize(@config : Config)
    end
    
    def build(content : Array(Models::ProcessedContent)) : Models::Site
      # Organize content
      sections = group_by_section(content)
      taxonomies = build_taxonomies(content)
      
      # Create immutable site model
      Models::Site.new(
        pages: content,
        config: @config,
        sections: sections,
        taxonomies: taxonomies
      )
    end
    
    private def group_by_section(content) : Hash(String, Array(ProcessedContent))
      content.group_by(&.section)
    end
    
    private def build_taxonomies(content) : Hash
      # Group by tags, categories, etc.
    end
  end
end
```

### **Stage 4: Renderer**

```crystal
module Lapis::Pipeline
  class Renderer
    def initialize(@config : Config, @template_engine : TemplateEngine)
    end
    
    def render_all(site : Models::Site) : Array(Models::RenderedPage)
      site.pages.flat_map { |page| render_page(page, site) }
    end
    
    private def render_page(page : ProcessedContent, site : Site) : Array(RenderedPage)
      # Render in all output formats
      formats = @config.output_formats.formats_for_kind(page.kind)
      
      formats.map do |format|
        html = @template_engine.render(page, site, format)
        path = output_path(page, format)
        Models::RenderedPage.new(html, path, page.metadata)
      end
    end
  end
end
```

### **Stage 5: File Writer**

```crystal
module Lapis::Pipeline
  class FileWriter
    def initialize(@output_dir : String)
    end
    
    def write_all(pages : Array(Models::RenderedPage))
      pages.each { |page| write_page(page) }
    end
    
    private def write_page(page : Models::RenderedPage)
      File.write(page.path, page.html)
    end
  end
end
```

---

## 🔄 Simplified Generator

```crystal
module Lapis
  class Generator
    def initialize(@config : Config)
      @pipeline = Pipeline::BuildPipeline.new(@config)
      @plugin_manager = PluginManager.new(@config)
    end
    
    def build
      Logger.info("Starting build")
      
      # Emit events
      @plugin_manager.emit(PluginEvent::BeforeBuild)
      
      # Run the pipeline
      @pipeline.run
      
      # Emit events
      @plugin_manager.emit(PluginEvent::AfterBuild)
      
      Logger.info("Build complete")
    end
  end
end
```

**That's it!** Generator is now ~20 lines instead of 1000.

---

## 🎨 Simplified Template Engine

```crystal
module Lapis
  class TemplateEngine
    def initialize(@config : Config, @theme_manager : ThemeManager)
      # No circular dependency on Generator!
    end
    
    # Accept Site directly - no need to create it
    def render(page : ProcessedContent, site : Site, format : OutputFormat?) : String
      context = TemplateContext.new(@config, page, site)
      template = load_template(page.kind, format)
      
      # Process template with context
      result = process_partials(template, context)
      result = process_variables(result, context)
      result
    end
    
    private def process_variables(template : String, context : TemplateContext) : String
      # Simple variable replacement
      # No FunctionProcessor creating Site objects!
      VariableProcessor.new(context).process(template)
    end
  end
end
```

---

## 📉 Eliminated Complexity

### **Before v0.5**
```
Content (class, mutable)
  ↓ wrapped by
Page (class, references Content + Site)
  ↓ lives in
Site (class, array of Content, creates Pages)
  ↓ referenced by
ContentQuery (class, has site_content)
  ↓ used by
TemplateContext (struct, has query)
  ↓ used by
FunctionProcessor (creates NEW Site!)
  ↓ creates
Page (again!)

= 7 layers, circular dependencies, O(n²) memory
```

### **After v0.5**
```
RawContent (struct, immutable)
  ↓ processed to
ProcessedContent (struct, immutable)
  ↓ organized in
Site (struct, immutable, contains array)
  ↓ passed to
TemplateContext (struct, has site reference)
  ↓ used by
VariableProcessor (simple substitution)

= 3 layers, no circles, O(n) memory
```

---

## 🗺️ Migration Strategy

### **Phase 1: Create Parallel Implementation** (Week 1)
- ✅ Implement new pipeline in `src/lapis/pipeline/`
- ✅ Keep old code untouched
- ✅ Add feature flag: `config.use_new_pipeline = true`
- ✅ Write tests for new pipeline

### **Phase 2: Gradual Cutover** (Week 2)
- ✅ Test new pipeline with exampleSite
- ✅ Fix bugs in new pipeline
- ✅ Port missing features
- ✅ Make new pipeline the default

### **Phase 3: Remove Old Code** (Week 3)
- ✅ Delete old Generator implementation
- ✅ Delete wrapper classes (Page, ContentQuery)
- ✅ Update all tests
- ✅ Update documentation

### **Phase 4: Polish** (Week 4)
- ✅ Performance optimization
- ✅ Memory profiling
- ✅ Integration tests
- ✅ Release v0.5.0

---

## 🧪 Testing Strategy

### **Unit Tests** (Easy with New Architecture!)

```crystal
describe ContentLoader do
  it "loads markdown files" do
    loader = ContentLoader.new(config)
    raw = loader.load_all
    raw.size.should eq(5)
    raw.first.markdown.should contain("# Hello")
  end
end

describe ContentProcessor do
  it "processes markdown to HTML" do
    processor = ContentProcessor.new(config)
    raw = RawContent.new("test.md", {...}, "# Hello")
    
    processed = processor.process_one(raw)
    processed.html.should contain("<h1>Hello</h1>")
  end
end

describe SiteBuilder do
  it "organizes content by section" do
    builder = SiteBuilder.new(config)
    content = [...]
    
    site = builder.build(content)
    site.sections["posts"].size.should eq(3)
  end
end
```

**No mocks needed!** Pure functions with clear inputs/outputs.

---

## 📈 Performance Improvements

### **Memory Usage**
| Operation | Before | After | Improvement |
|-----------|--------|-------|-------------|
| Load 100 pages | ~500 objects | ~100 objects | **5x less** |
| Render all | O(n²) Site creation | O(n) single Site | **n times less** |
| Peak memory | High (duplicates) | Low (single copy) | **~50% reduction** |

### **Build Speed**
| Site Size | Before | After | Improvement |
|-----------|--------|-------|-------------|
| 10 pages | 20ms | 15ms | 25% faster |
| 100 pages | 500ms | 200ms | **2.5x faster** |
| 1000 pages | 30s | 5s | **6x faster** |

*(Estimates based on eliminating O(n²) patterns)*

---

## 🎯 Success Criteria

### **Must Have** (v0.5.0)
- ✅ All tests pass
- ✅ No circular dependencies
- ✅ Build speed improved >2x
- ✅ Memory usage reduced >30%
- ✅ Code coverage >80%

### **Nice to Have** (v0.5.1+)
- ✅ Parallel processing (real, not fake)
- ✅ Incremental builds (proper implementation)
- ✅ Plugin system improvements
- ✅ Better error messages

---

## 💡 Quick Wins Before v0.5

Things you can do NOW to prepare:

### **1. Add Tests for Current Behavior**
```crystal
# These tests will survive the refactor
describe "Build Output" do
  it "generates correct HTML" do
    generator = Generator.new(config)
    generator.build
    
    output = File.read("public/index.html")
    output.should contain("<h1>Welcome</h1>")
  end
end
```

### **2. Document Current Architecture**
Add comments explaining:
- Why Site is created multiple times
- Why Generator is so big
- Where the circular dependencies are

### **3. Extract Pure Functions**
```crystal
# Move these out of Generator
module URLGenerator
  def self.generate(path : String, metadata : Metadata) : String
    # Pure function, easy to test
  end
end
```

### **4. Add Benchmarks**
```crystal
Benchmark.ips do |x|
  x.report("build_site") { generator.build }
end
```

Track performance before and after refactor.

---

## 🚀 Beyond v0.5.0

### **v0.6.0 - Plugin Architecture**
- Event-driven plugins
- Third-party themes
- Custom shortcodes
- Hook system

### **v0.7.0 - Advanced Features**
- Watch mode with proper incremental rebuilds
- Live reload with WebSockets
- Source maps for debugging
- Content validation

### **v1.0.0 - Production Ready**
- Battle-tested
- Full documentation
- Performance guarantees
- Stable API

---

## 📚 Resources

### **Design Patterns**
- Pipeline Pattern: [Pipes and Filters](https://www.enterpriseintegrationpatterns.com/patterns/messaging/PipesAndFilters.html)
- Immutability: [Functional Core, Imperative Shell](https://www.destroyallsoftware.com/screencasts/catalog/functional-core-imperative-shell)
- Clean Architecture: [Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

### **Similar Projects**
- Hugo (Go) - Uses pipeline architecture
- Zola (Rust) - Immutable site model
- Eleventy (JS) - Transform pipeline

---

## ⚠️ Important Notes

### **DON'T Refactor If:**
- ❌ Current version works for users
- ❌ No performance complaints yet
- ❌ Users want features, not rewrites
- ❌ You're still learning the domain

### **DO Refactor When:**
- ✅ You have real user feedback
- ✅ Performance is provably bad
- ✅ Adding features is painful
- ✅ You understand the problem deeply

---

## 🎊 Conclusion

**Current architecture (v0.4.0)**: Good enough to ship!  
**Proposed architecture (v0.5.0)**: Will scale better long-term.

**Timeline**:
- **Now**: Ship v0.4.1 (fix Markd workaround)
- **1 month**: Gather user feedback
- **2 months**: Start v0.5.0 refactor
- **3 months**: Release v0.5.0

**Remember**: 
> "Make it work, make it right, make it fast" - Kent Beck

We're at "make it work" ✅  
Next is "make it right" 🎯  
Then "make it fast" 🚀

---

*Roadmap created: October 2, 2025*  
*Target release: v0.5.0 (December 2025)*  
*Estimated effort: 2-3 weeks focused work*  
*Risk level: Medium (breaking changes, but testable)*

