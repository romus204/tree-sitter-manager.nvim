; inherits: html,html_tags

(raw_text) @none

((tag_name) @type
  (#match? @type "^[A-Z]"))

(tag_name
  namespace: (tag_namespace) @keyword
  ":" @punctuation.delimiter
  name: (tag_local_name) @tag)

(tag_name
  object: (tag_member) @type
  "." @punctuation.delimiter
  property: (tag_member) @tag)

(attribute_directive) @keyword

(attribute_name
  ":" @punctuation.delimiter)

(attribute_identifier) @property

(attribute_modifier) @attribute

(attribute_modifiers
  "|" @punctuation.delimiter)

(shorthand_attribute
  content: (_) @variable)

((start_tag) @_start_tag
  (#set! @_start_tag bo.commentstring "// %s"))

((self_closing_tag) @_self_closing_tag
  (#set! @_self_closing_tag bo.commentstring "// %s"))

((attribute) @_attribute
  (#set! @_attribute bo.commentstring "// %s"))

((shorthand_attribute) @_shorthand_attribute
  (#set! @_shorthand_attribute bo.commentstring "// %s"))

((tag_comment) @_tag_comment
  (#set! @_tag_comment bo.commentstring "// %s"))

[
  "{"
  "}"
] @punctuation.bracket

"|" @punctuation.delimiter

(tag_comment
  kind: (line_comment) @comment)

(tag_comment
  kind: (block_comment) @comment)

(block_open) @tag.delimiter
(block_close) @tag.delimiter

((block_keyword) @keyword.conditional
  (#eq? @keyword.conditional "if"))

((block_keyword) @keyword.repeat
  (#eq? @keyword.repeat "each"))

((block_keyword) @keyword.coroutine
  (#eq? @keyword.coroutine "await"))

((block_keyword) @keyword
  (#any-of? @keyword "key" "snippet"))

((branch_kind) @keyword.conditional
  (#any-of? @keyword.conditional "else" "else if"))

((branch_kind) @keyword.coroutine
  (#eq? @keyword.coroutine "then"))

((branch_kind) @keyword.exception
  (#eq? @keyword.exception "catch"))

((shorthand_kind) @keyword.coroutine
  (#eq? @keyword.coroutine "then"))

((shorthand_kind) @keyword.exception
  (#eq? @keyword.exception "catch"))

(block_sigil) @keyword

(html_tag
  "html" @keyword)

(render_tag
  "render" @keyword)

(attach_tag
  "attach" @keyword)

(key_block
  "key" @keyword)

(snippet_block
  "snippet" @keyword
  name: (snippet_name) @function)

(const_tag
  "const" @keyword.modifier)

(declaration_kind) @keyword.modifier

(debug_tag
  "debug" @keyword.debug)

(if_block
  "if" @keyword.conditional)

(each_block
  "each" @keyword.repeat)

(await_block
  "await" @keyword.coroutine)

"as" @keyword

(snippet_type_parameters) @type
