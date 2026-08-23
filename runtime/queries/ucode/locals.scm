; Locals queries for ucode.
; Used by editors for rename, go-to-definition, and scope-aware highlight.

; -------------------------------------------------------------------------
; Scopes
; -------------------------------------------------------------------------

(program) @local.scope
(function_declaration) @local.scope
(function_expression) @local.scope
(arrow_function) @local.scope
; statement_block provides block scoping for let/const
(statement_block) @local.scope
; for loops scope their initialiser variable(s) to the loop body
(for_statement) @local.scope
(for_alt_statement) @local.scope
(for_in_statement) @local.scope
(for_in_alt_statement) @local.scope
; catch clause scopes its parameter to the handler body
(catch_clause) @local.scope

; -------------------------------------------------------------------------
; Definitions — functions
; -------------------------------------------------------------------------

; Function declaration names belong to the enclosing scope so that
; callers outside the function body can resolve them.
;
; NOTE: tree-sitter does not evaluate #set! predicates — it has no built-in
; concept of "place this definition one scope level up." This annotation is
; metadata only; the consumer must detect it (predicate name and args) and
; implement the scope-parent walk itself. A consumer that builds a
; scope -> definitions map by structural nesting alone will misplace this
; definition: it will end up invisible to callers outside the function body.
(function_declaration
  name: (identifier) @local.definition.function
  (#set! definition.function.scope parent))

; Named function expressions (let f = function foo() {}) keep their name
; *inside* the expression scope — foo is only visible for self-recursion,
; not to the surrounding block.  No (#set! parent) here.
(function_expression
  name: (identifier) @local.definition.function)

; -------------------------------------------------------------------------
; Definitions — variables
; -------------------------------------------------------------------------

(variable_declarator
  name: (identifier) @local.definition.var)

; -------------------------------------------------------------------------
; Definitions — parameters
; -------------------------------------------------------------------------

(formal_parameters (identifier) @local.definition.parameter)
(rest_element (identifier) @local.definition.parameter)
(arrow_function parameter: (identifier) @local.definition.parameter)

; catch clause binding
(catch_clause
  parameter: (identifier) @local.definition.var)

; -------------------------------------------------------------------------
; Definitions — for-in loop variables
;
; Only capture when let/const is present (kind field exists).  A bare
; `for (k in obj)` is an assignment to an existing variable, not a new
; binding; tagging it as a definition would incorrectly shadow the outer `k`.
; -------------------------------------------------------------------------

(for_in_statement
  kind: _
  left: (identifier) @local.definition.var)
(for_in_statement
  kind: _
  value: (identifier) @local.definition.var)
(for_in_alt_statement
  kind: _
  left: (identifier) @local.definition.var)
(for_in_alt_statement
  kind: _
  value: (identifier) @local.definition.var)

; -------------------------------------------------------------------------
; Definitions — imports
; -------------------------------------------------------------------------

; import def from "./mod.uc"
(import_clause (identifier) @local.definition.import)

; import * as ns from "./mod.uc"
(namespace_import (identifier) @local.definition.import)

; import { a } from "./mod.uc"  — name IS the local binding (no alias)
(import_specifier
  name: (identifier) @local.definition.import
  !alias)

; import { a as x } from "./mod.uc"  — only the alias is the local binding
(import_specifier
  alias: (identifier) @local.definition.import)

; -------------------------------------------------------------------------
; References
; -------------------------------------------------------------------------

(identifier) @local.reference
