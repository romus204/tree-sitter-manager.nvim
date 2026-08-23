; Tags queries for ucode.
; Used by GitHub code navigation and tools that index symbol definitions.
;
; NOTE on #strip! and #select-adjacent!: these are non-standard predicates with
; no tree-sitter runtime support — tree-sitter only evaluates #eq?/#match?/
; #not-match?-family predicates and filters non-matching captures; everything
; else (including these two) passes through as metadata for the consumer to
; act on. A consumer that reads @doc captures verbatim gets raw `/** ... */`
; text with leading `*` characters intact (no #strip!), and may associate a
; comment from several lines above with the wrong definition (no
; #select-adjacent!). Expected semantics:
;   #strip! @capture <regex>        — strip text matching <regex> from the
;                                      start/end of @capture's text.
;   #select-adjacent! @a @b         — only keep this match if @a is on a line
;                                      immediately preceding @b (no blank
;                                      lines or other statements between).

; -------------------------------------------------------------------------
; Function definitions — named declarations (brace body or endfunction body)
; -------------------------------------------------------------------------

(
  (comment)* @doc
  .
  (function_declaration
    name: (identifier) @name) @definition.function
  (#strip! @doc "^[\\s\\*/]+|^[\\s\\*/]$")
  (#select-adjacent! @doc @definition.function)
)

; -------------------------------------------------------------------------
; Function definitions — named function expressions
; -------------------------------------------------------------------------

(
  (comment)* @doc
  .
  (function_expression
    name: (identifier) @name) @definition.function
  (#strip! @doc "^[\\s\\*/]+|^[\\s\\*/]$")
  (#select-adjacent! @doc @definition.function)
)

; -------------------------------------------------------------------------
; Function definitions — let/const assigned a function or arrow
; -------------------------------------------------------------------------

(
  (comment)* @doc
  .
  (lexical_declaration
    (variable_declarator
      name: (identifier) @name
      value: [(function_expression) (arrow_function)])) @definition.function
  (#strip! @doc "^[\\s\\*/]+|^[\\s\\*/]$")
  (#select-adjacent! @doc @definition.function)
)

; -------------------------------------------------------------------------
; Function definitions — assignment of function to variable or property
; -------------------------------------------------------------------------

(assignment_expression
  left: [
    (identifier) @name
    (member_expression
      property: (property_identifier) @name)
  ]
  right: [(function_expression) (arrow_function)]) @definition.function

; -------------------------------------------------------------------------
; Function definitions — object method pairs  { key: function() {} }
; -------------------------------------------------------------------------

(pair
  key: (property_identifier) @name
  value: [(function_expression) (arrow_function)]) @definition.function

; -------------------------------------------------------------------------
; Constants — exported scalar / expression values
; -------------------------------------------------------------------------

(export_statement
  (lexical_declaration
    (variable_declarator
      name: (identifier) @name
      value: [
        (number) (string) (true) (false) (null)
        (identifier) (binary_expression) (call_expression)
      ])) @definition.constant)

; -------------------------------------------------------------------------
; References — function calls
; -------------------------------------------------------------------------

(
  (call_expression
    function: (identifier) @name) @reference.call
  (#not-match? @name "^(require|include|render)$")
)

(call_expression
  function: (member_expression
    property: (property_identifier) @name)) @reference.call
