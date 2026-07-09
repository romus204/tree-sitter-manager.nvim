; inherits: html

(snippet_block) @local.scope

(snippet_parameters
  parameter: (pattern) @local.definition.parameter)

(snippet_name) @local.definition.function

((const_tag
  expression: (expression_value
    content: (_) @local.definition))
  (#match? @local.definition "\\S"))

((declaration_tag
  declaration: (expression_value
    content: (_) @local.definition))
  (#match? @local.definition "\\S"))

((tag_name) @local.reference
  (#lua-match? @local.reference "^[A-Z]"))

(tag_name
  object: (tag_member) @local.reference
  property: (tag_member) @local.reference)
