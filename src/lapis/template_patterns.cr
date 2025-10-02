module Lapis
  # Shared template patterns for consistent regex compilation across all processors
  # This module eliminates duplication between TemplateProcessor and FunctionProcessor
  module TemplatePatterns
    # Compile-time regexes for template processing
    # These patterns are used by both TemplateProcessor and FunctionProcessor

    # Conditional patterns
    IF_CONDITIONAL_PATTERN      = /\{\{\s*if\s+([^}]+)\s*\}\}(.*?)\{\{\s*endif\s*\}\}/m
    IF_ELSE_CONDITIONAL_PATTERN = /\{\{\s*if\s+([^}]+)\s*\}\}(.*?)\{\{\s*else\s*\}\}(.*?)\{\{\s*endif\s*\}\}/m

    # Loop patterns
    FOR_LOOP_PATTERN   = /\{\{\s*for\s+(\w+)\s+in\s+([^}]+)\s*\}\}(.*?)\{\{\s*endfor\s*\}\}/m
    RANGE_LOOP_PATTERN = /\{\{\s*range\s+([^}]+)\s*\}\}(.*?)\{\{\s*end\s*\}\}/m

    # Variable and function patterns
    VARIABLE_PATTERN      = /\{\{\s*([^}]+)\s*\}\}/
    FUNCTION_CALL_PATTERN = /\{\{\s*(\w+)\s*\(([^)]*)\)\s*\}\}/

    # Method and filter patterns
    METHOD_CALL_PATTERN = /(\w+)\(([^)]*)\)/
    FILTER_PATTERN      = /(\w+)\(([^)]*)\)/

    # Control structure patterns
    ELSE_PATTERN   = /\{\{\s*else\s*\}\}/
    ENDIF_PATTERN  = /\{\{\s*endif\s*\}\}/
    ENDFOR_PATTERN = /\{\{\s*endfor\s*\}\}/
    END_PATTERN    = /\{\{\s*end\s*\}\}/

    # Cleanup patterns for malformed syntax
    MALFORMED_IF_PATTERN       = /\{\{\s*if\s+[^}]*\}\}/
    MALFORMED_FOR_PATTERN      = /\{\{\s*for\s+\w+\s+in\s+[^}]*\}\}/
    REMAINING_TEMPLATE_PATTERN = /\{\{\s*[^}]*\s*\}\}/

    # HTML cleanup patterns
    EMPTY_TAG_PATTERN         = />\s*">\s*</
    EMPTY_TAG_NEWLINE_PATTERN = />\s*">\s*\n/
    EMPTY_TAG_END_PATTERN     = />\s*">/
  end
end
