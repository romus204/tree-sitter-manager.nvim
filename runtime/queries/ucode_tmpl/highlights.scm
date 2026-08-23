; Markup-mode highlights for ucode_markup grammar
; (.uc.tmpl files)

; ── Tag delimiters ────────────────────────────────────────────────────────────

(statement_tag_open)        @punctuation.special
(statement_tag_trim_open)   @punctuation.special
(statement_tag_lstrip_open) @punctuation.special
(statement_tag_close)       @punctuation.special
(statement_tag_trim_close)  @punctuation.special
(expression_tag_open)       @punctuation.special
(expression_tag_trim_open)  @punctuation.special
(expression_tag_close)      @punctuation.special
(expression_tag_trim_close) @punctuation.special

; ── Comment tags ─────────────────────────────────────────────────────────────

(comment_tag) @comment

; ── Alt-syntax structural keywords ────────────────────────────────────────────
;
; These tokens appear between the tag-open external token and the close of the
; alt header (before the : that ends the condition/header).  They are not
; injected — they are literal tokens visible in the ucode_markup parse tree.

["if" "elif" "else" "endif"]        @keyword.conditional
["for" "endfor" "while" "endwhile"] @keyword.repeat
"in"                                @keyword.operator

(if_alt_statement     ":" @punctuation.delimiter)
(elif_clause_tag      ":" @punctuation.delimiter)
(for_alt_statement    ":" @punctuation.delimiter)
(for_in_alt_statement ":" @punctuation.delimiter)
(while_alt_statement  ":" @punctuation.delimiter)
(function_declaration ":" @punctuation.delimiter)

; ── Code tokens inside statement/expression tags are highlighted via injection ─
; (see ucode_tmpl/injections.scm)
