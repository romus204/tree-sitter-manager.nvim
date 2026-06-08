; Highlight queries for ucode_tmpl.
; Template structure is styled here; ucode code inside tags is highlighted
; via language injection (see injections.scm).

; -------------------------------------------------------------------------
; Tag delimiters
; -------------------------------------------------------------------------

[
  "{%"  "%}"
  "{%-" "-%}"
  "{%+"
  "{{"  "}}"
  "{{-" "-}}"
  "{#"  "#}"
  "{#-" "-#}"
] @keyword

; -------------------------------------------------------------------------
; Template comments
; -------------------------------------------------------------------------

(comment_tag) @comment @spell
