(element) @function.outer

(element
  (start_tag)
  .
  (_) @function.inner
  .
  (end_tag))

(element
  (start_tag)
  _+ @function.inner
  (end_tag))

(self_closing_tag
  "<"
  .
  (_) @function.inner
  .
  "/>")

(self_closing_tag
  "<"
  .
  (_) @function.inner
  (_)+
  (_) @function.inner
  .
  "/>")

(self_closing_tag) @function.outer

(snippet_block) @function.outer

(render_tag) @call.outer

(render_tag
  (expression_value) @call.inner)

(attach_tag) @call.outer

(attach_tag
  (expression_value) @call.inner)

(html_tag) @statement.outer

(const_tag) @statement.outer @assignment.outer

(const_tag
  (expression_value) @assignment.inner)

(declaration_tag) @statement.outer @assignment.outer

(declaration_tag
  (expression_value) @assignment.inner)

(debug_tag) @statement.outer

(doctype) @statement.outer

(attribute_value) @attribute.inner

(attribute) @attribute.outer

((attribute
  (expression
    content: (_) @attribute.inner)))

((attribute
  (shorthand_attribute
    content: (_) @attribute.inner)))

((element
  (start_tag
    (tag_name) @_tag)) @class.outer
  (#match? @_tag "^(html|section|h[0-9]|header|title|head|body)$"))

((element
  (start_tag
    (tag_name) @_tag)
  .
  (_) @class.inner
  .
  (end_tag))
  (#match? @_tag "^(html|section|h[0-9]|header|title|head|body)$"))

((element
  (start_tag
    (tag_name) @_tag)
  _+ @class.inner
  (end_tag))
  (#match? @_tag "^(html|section|h[0-9]|header|title|head|body)$"))

((comment) @comment.inner @comment.outer
  (#offset! @comment.inner 0 4 0 -3))

(tag_comment) @comment.outer

((tag_comment
  (line_comment) @comment.inner)
  (#offset! @comment.inner 0 2 0 0))

((tag_comment
  (block_comment) @comment.inner)
  (#offset! @comment.inner 0 2 0 -2))

(if_block) @block.outer @conditional.outer

(if_block
  (block_close)
  .
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ] @block.inner @conditional.inner
  .
  [
    (else_if_clause)
    (else_clause)
    (block_end)
  ])

(if_block
  (block_close)
  .
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ] @block.inner @conditional.inner
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ]+
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ] @block.inner @conditional.inner
  .
  [
    (else_if_clause)
    (else_clause)
    (block_end)
  ])

(else_if_clause) @conditional.outer

(else_if_clause
  (block_close)
  .
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ] @conditional.inner)

(else_if_clause
  (block_close)
  .
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ] @conditional.inner
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ]+
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ] @conditional.inner)

(else_clause) @conditional.outer

(else_clause
  (block_close)
  .
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ] @conditional.inner)

(else_clause
  (block_close)
  .
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ] @conditional.inner
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ]+
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ] @conditional.inner)

(each_block) @block.outer @loop.outer

(each_block
  (block_close)
  .
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ] @block.inner @loop.inner
  .
  (block_end))

(each_block
  (block_close)
  .
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ] @block.inner @loop.inner
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ]+
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ] @block.inner @loop.inner
  .
  (block_end))

(await_block) @block.outer

(await_block
  (block_close)
  .
  (await_pending) @block.inner
  .
  [
    (await_branch)
    (block_end)
  ])

(await_branch) @block.outer

(await_branch) @conditional.outer

(await_branch
  (await_branch_children) @block.inner)

(await_branch
  (await_branch_children) @conditional.inner)

(key_block) @block.outer

(key_block
  (block_close)
  .
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ] @block.inner
  .
  (block_end))

(key_block
  (block_close)
  .
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ] @block.inner
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ]+
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ] @block.inner
  .
  (block_end))

(snippet_block) @block.outer

(snippet_block
  (block_close)
  .
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ] @block.inner @function.inner
  .
  (block_end))

(snippet_block
  (block_close)
  .
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ] @block.inner @function.inner
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ]+
  [
    (comment)
    (text)
    (expression)
    (element)
    (html_tag)
    (render_tag)
    (attach_tag)
    (const_tag)
    (declaration_tag)
    (debug_tag)
    (if_block)
    (each_block)
    (await_block)
    (key_block)
    (snippet_block)
  ] @block.inner @function.inner
  .
  (block_end))

(each_block
  "as"
  .
  (pattern) @parameter.inner @parameter.outer
  .
  ","? @parameter.outer)

(each_block
  "," @parameter.outer
  .
  (pattern) @parameter.inner @parameter.outer)

(await_branch
  (pattern) @parameter.inner @parameter.outer)

(snippet_parameters
  "," @parameter.outer
  .
  (pattern) @parameter.inner @parameter.outer)

(snippet_parameters
  .
  (pattern) @parameter.inner @parameter.outer
  .
  ","? @parameter.outer)
