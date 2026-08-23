; Inject ucdocs into JSDoc block comments (/** ... */).
; The [^*/] guard excludes /*** section dividers (≥3 stars) and /**/ (empty, non-JSDoc).
((comment) @injection.content
  (#match? @injection.content "^/\\*\\*[^*/]")
  (#set! injection.language "ucdocs"))
