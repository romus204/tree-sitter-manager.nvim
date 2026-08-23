; Fold queries for ucode_markup.

; Code-level folds — same structures appear as real AST nodes inside tags
[
  (statement_block)
  (switch_body)
  (object)
  (array)
] @fold

; Alt-syntax template blocks — fold the entire construct
[
  (if_alt_statement)
  (for_alt_statement)
  (for_in_alt_statement)
  (while_alt_statement)
] @fold

; Colon-body function declarations inside statement tags
(function_declaration "endfunction") @fold
