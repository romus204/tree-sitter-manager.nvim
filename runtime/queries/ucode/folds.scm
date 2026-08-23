; Fold queries for ucode.
; Each captured node becomes a collapsible fold region.

; -------------------------------------------------------------------------
; Brace-delimited blocks
;
; statement_block covers brace-body function_declaration, function_expression,
; and arrow_function bodies — the signature line stays visible because the
; fold starts at '{', not at the 'function' keyword.
; -------------------------------------------------------------------------

[
  (statement_block)
  (switch_body)
  (object)
  (array)
] @fold

; -------------------------------------------------------------------------
; Alternative (colon/endif) syntax — fold the entire construct
; -------------------------------------------------------------------------

[
  (if_alt_statement)
  (for_alt_statement)
  (for_in_alt_statement)
  (while_alt_statement)
] @fold

; -------------------------------------------------------------------------
; Colon-body function declaration (function f(): ... endfunction)
;
; Brace-body function declarations are folded via (statement_block) above.
; The colon form has no statement_block, so we fold the whole declaration.
; We filter on "endfunction" so this pattern only matches the colon form.
; -------------------------------------------------------------------------

(function_declaration "endfunction") @fold
