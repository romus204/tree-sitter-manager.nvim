; Tags queries for ucode_markup.
; The markup grammar produces a unified tree — function declarations and
; other named symbols inside {% %} tags are real AST nodes, so the same
; patterns as the code grammar apply here.

(
  (comment)* @doc
  .
  (function_declaration
    name: (identifier) @name) @definition.function
  (#strip! @doc "^[\\s\\*/]+|^[\\s\\*/]$")
  (#select-adjacent! @doc @definition.function)
)

(
  (comment)* @doc
  .
  (function_expression
    name: (identifier) @name) @definition.function
  (#strip! @doc "^[\\s\\*/]+|^[\\s\\*/]$")
  (#select-adjacent! @doc @definition.function)
)

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

(assignment_expression
  left: [
    (identifier) @name
    (member_expression
      property: (property_identifier) @name)
  ]
  right: [(function_expression) (arrow_function)]) @definition.function

(pair
  key: (property_identifier) @name
  value: [(function_expression) (arrow_function)]) @definition.function

(export_statement
  (lexical_declaration
    (variable_declarator
      name: (identifier) @name
      value: [
        (number) (string) (true) (false) (null)
        (identifier) (binary_expression) (call_expression)
      ])) @definition.constant)

(
  (call_expression
    function: (identifier) @name) @reference.call
  (#not-match? @name "^(require|include|render)$")
)

(call_expression
  function: (member_expression
    property: (property_identifier) @name)) @reference.call
