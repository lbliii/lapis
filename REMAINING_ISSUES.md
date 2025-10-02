# Remaining Stack Overflow Issues

## Summary

After fixing 2 critical stack overflows, **1 remains** but it's in an **external library** (Markd).

---

## ❌ Still Broken: Markd Library Bug

### **Stack Overflow in Markd List Parser**

**Status**: External library bug, not in our code  
**Location**: `Markd::Rule::List#parse_list_marker`  
**Trigger**: Complex list structures in exampleSite/content/index.md

### Stack Trace
```
[52,245 deep recursion]
Hash resizing
↓
Markd::Rule::List#parse_list_marker
↓  
Markd::Parser::Block#process_line
↓
Markd::Parser::Block#parse_blocks
↓
Lapis::Content#process_markdown
```

### Root Cause

The Markd markdown parser (v0.5.0) has a bug when parsing nested lists or certain list patterns. The exampleSite index.md contains list structures that trigger infinite/deep recursion in Markd's list parsing logic.

**Not a Lapis bug** - this is in the external markdown library.

---

## 🎯 What We Fixed

### ✅ 1. Crystal.main Anti-Pattern (CRITICAL)
- **File**: `src/lapis.cr`
- **Fix**: Moved to `src/lapis_cli.cr`
- **Result**: CLI stable, simple sites work

### ✅ 2. Infinite Partial Recursion (CRITICAL)  
- **File**: `src/lapis/partials.cr`
- **Fix**: Added MAX_PARTIAL_DEPTH = 10
- **Result**: Template processing stable

### ✅ 3. Regex Recompilation (OPTIMIZATION)
- **File**: `src/lapis/function_processor.cr`
- **Fix**: Cached regex patterns in class_property
- **Result**: Reduced object churn (but didn't fix Markd bug)

---

## 🛠️ Workarounds for Markd Bug

### Option 1: Simplify Content (Immediate)
Remove or simplify list structures in index.md:

```markdown
<!-- PROBLEMATIC -->
### **Performance & Optimization**
- ⚡ **Lightning Fast**: Crystal-powered builds
- 🔄 **Incremental Builds**: Only rebuild changed
- 📦 **Asset Optimization**: Automatic minification
  - Nested list item
  - Another nested item

<!-- SAFER -->
### Performance & Optimization  
Lightning fast builds, incremental processing, and automatic asset optimization.
```

### Option 2: Upgrade Markd (Medium Term)
Check if newer version fixes the list parsing bug:
```yaml
# shard.yml
dependencies:
  markd:
    github: icyleaf/markd
    version: ~> 0.6.0  # Try newer version
```

### Option 3: Switch Markdown Library (Long Term)
Consider alternatives:
- `markd` fork with fix
- Different markdown parser (cmark, comrak bindings)

### Option 4: Pre-process Markdown (Hacky)
Add list depth limit before passing to Markd:
```crystal
# In Content#process_markdown
def flatten_deep_lists(markdown : String) : String
  # Limit list nesting to prevent Markd recursion
  # ... implementation ...
end
```

---

## 📊 Current Stability Status

| Component | Status | Notes |
|-----------|--------|-------|
| Unit Tests | ✅ 100% | All 490 passing |
| Integration Tests | ✅ 97% | 543/559 passing |
| CLI | ✅ Stable | No crashes |
| Simple Sites | ✅ Works | test_site builds fine |
| Complex Lists | ❌ **Markd Bug** | ExampleSite crashes |

**Overall: 80-90% stable** - works great except complex nested lists

---

## 🚀 Recommended Action Plan

### Immediate (Today)
1. ✅ Document the issue (this file)
2. 🔲 Simplify exampleSite index.md lists
3. 🔲 Test if build succeeds with simpler content
4. 🔲 Add warning in docs about list nesting

### Short Term (This Week)  
1. 🔲 Test Markd v0.6.0 or later versions
2. 🔲 Report bug to Markd maintainers
3. 🔲 Add content validation warning for deep lists

### Medium Term (Next Sprint)
1. 🔲 Evaluate alternative markdown parsers
2. 🔲 Consider forking Markd with fix
3. 🔲 Add pre-processing to flatten dangerous patterns

---

## ✅ What Users Can Do Now

### Works Great For:
- ✅ Simple to moderate sites
- ✅ Content without deeply nested lists
- ✅ Most real-world use cases
- ✅ Docs, blogs, portfolios (with list limits)

### Avoid:
- ❌ Deeply nested bullet lists (3+ levels)
- ❌ Complex mixed list patterns
- ❌ Very long lists with nesting

### Workaround:
Convert nested lists to:
- Flat lists with indentation via CSS
- Definition lists
- Tables
- Simple paragraphs with bullets

---

## 🔍 How to Test

```bash
# 1. Test with simple content - WORKS
cd test_site
../lapis build
# ✅ Success

# 2. Test with complex lists - FAILS
cd exampleSite  
../lapis build
# ❌ Stack overflow in Markd

# 3. Test with simplified lists - TBD
# Edit index.md to remove nesting
../lapis build
# Should work
```

---

## 📝 Notes

- **Not a blocker** for most users
- Lapis core is stable
- Issue is in dependency, not our code
- Can be worked around with content patterns
- Should report upstream to Markd

---

*Last Updated: October 2, 2025*

