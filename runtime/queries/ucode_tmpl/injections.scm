; Injection queries for ucode_tmpl.
; Instructs editors to parse code/expression block content as ucode.

((statement_tag (code) @injection.content)
 (#set! injection.language "ucode"))

((expression_tag (code) @injection.content)
 (#set! injection.language "ucode"))
