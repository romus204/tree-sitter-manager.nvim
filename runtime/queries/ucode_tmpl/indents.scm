; Indentation queries for ucode_markup.

; ── Brace-delimited constructs inside statement tags ──────────────────────────

[
  (statement_block)
  (switch_body)
  (object)
  (array)
  (arguments)
  (formal_parameters)
] @indent.begin

[
  "}"
  "]"
  ")"
] @indent.end

; ── Alt-syntax template blocks ────────────────────────────────────────────────

(if_alt_statement     ":" @indent.begin)
(elif_clause          ":" @indent.begin)
(for_alt_statement    ":" @indent.begin)
(for_in_alt_statement ":" @indent.begin)
(while_alt_statement  ":" @indent.begin)
(function_declaration ":" @indent.begin)

[
  "endif"
  "endfor"
  "endwhile"
  "endfunction"
] @indent.end

(else_clause        "else") @indent.branch
(else_alt_clause    "else") @indent.branch
(else_alt_clause_tag "else") @indent.branch
(elif_clause        "elif") @indent.branch
(elif_clause_tag    "elif") @indent.branch

; else variants have no ':' so @indent.branch alone doesn't open a body scope
(else_alt_clause)     @indent.begin
(else_alt_clause_tag) @indent.begin

(elif_clause_tag ":" @indent.begin)

; ── Switch ────────────────────────────────────────────────────────────────────

(switch_case    "case")    @indent.branch
(switch_default "default") @indent.branch
