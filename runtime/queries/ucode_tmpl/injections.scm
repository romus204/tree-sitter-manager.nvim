; Inject the ucode grammar into statement and expression tag bodies.
;
; The entire statement_tag (excluding open/close markers) and the expression
; inside an expression_tag are highlighted as ucode code.

(statement_tag
  ((_) @injection.content
    (#not-type? @injection.content
      statement_tag_open statement_tag_trim_open statement_tag_lstrip_open
      statement_tag_close statement_tag_trim_close))
  (#set! injection.language "ucode"))

(expression_tag
  ((_) @injection.content
    (#not-type? @injection.content
      expression_tag_open expression_tag_trim_open
      expression_tag_close expression_tag_trim_close))
  (#set! injection.language "ucode"))

; Alt-syntax header expressions.
;
; Conditions and loop headers live directly on the alt-syntax node, not
; inside a statement_tag, so the captures above do not reach them.  The
; `open: (_)` guard selects the markup form of each rule (the one with tag
; delimiters) and excludes the code form that appears inside statement_tag
; bodies (which are already covered by the statement_tag capture above).

(if_alt_statement    open: (_) condition: (_) @injection.content (#set! injection.language "ucode"))
(elif_clause_tag                condition: (_) @injection.content (#set! injection.language "ucode"))
(while_alt_statement open: (_) condition: (_) @injection.content (#set! injection.language "ucode"))

(for_alt_statement open: (_) initializer: (_) @injection.content
  (#not-type? @injection.content empty_statement)
  (#set! injection.language "ucode"))
(for_alt_statement open: (_) condition: (_) @injection.content
  (#not-type? @injection.content empty_statement)
  (#set! injection.language "ucode"))
(for_alt_statement open: (_) increment: (_) @injection.content (#set! injection.language "ucode"))

(for_in_alt_statement open: (_) right: (_) @injection.content (#set! injection.language "ucode"))

; Inject ucdocs into JSDoc block comments (/** ... */).
; The [^*/] guard excludes /*** section dividers (≥3 stars) and /**/ (empty, non-JSDoc).
((comment) @injection.content
  (#match? @injection.content "^/\\*\\*[^*/]")
  (#set! injection.language "ucdocs"))
