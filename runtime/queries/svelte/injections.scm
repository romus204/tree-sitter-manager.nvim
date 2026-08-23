((comment) @injection.content
  (#set! injection.language "comment"))

((element
  (start_tag
    (tag_name) @_tag) @_start_tag
  (raw_text) @injection.content)
  (#eq? @_tag "script")
  (#not-lua-match? @_start_tag "%slang%s*=")
  (#not-lua-match? @_start_tag "%stype%s*=")
  (#set! injection.language "javascript"))

((element
  (start_tag
    (tag_name) @_tag
    (attribute
      (attribute_name) @_lang
      (quoted_attribute_value
        (attribute_value) @_value)))
  (raw_text) @injection.content)
  (#eq? @_tag "script")
  (#eq? @_lang "lang")
  (#any-of? @_value "js" "javascript" "text/javascript")
  (#set! injection.language "javascript"))

((element
  (start_tag
    (tag_name) @_tag
    (attribute
      (attribute_name) @_lang
      (quoted_attribute_value
        (attribute_value) @_value)))
  (raw_text) @injection.content)
  (#eq? @_tag "script")
  (#eq? @_lang "lang")
  (#any-of? @_value "ts" "typescript" "text/typescript")
  (#set! injection.language "typescript"))

((element
  (start_tag
    (tag_name) @_tag
    (attribute
      (attribute_name) @_lang
      (quoted_attribute_value
        (attribute_value) @injection.language)))
  (raw_text) @injection.content)
  (#eq? @_tag "script")
  (#eq? @_lang "lang")
  (#not-any-of? @injection.language "js" "javascript" "text/javascript" "ts" "typescript" "text/typescript"))

((element
  (start_tag
    (tag_name) @_tag
    (attribute
      (attribute_name) @_attr
      (#eq? @_attr "type")
      (quoted_attribute_value
        (attribute_value) @_type)))
  (raw_text) @injection.content)
  (#eq? @_tag "script")
  (#eq? @_type "module")
  (#set! injection.language "javascript"))

((element
  (start_tag
    (tag_name) @_tag
    (attribute
      (attribute_name) @_attr
      (#eq? @_attr "type")
      (quoted_attribute_value
        (attribute_value) @_type)))
  (raw_text) @injection.content)
  (#eq? @_tag "script")
  (#eq? @_type "importmap")
  (#set! injection.language "json"))

((element
  (start_tag
    (tag_name) @_tag) @_start_tag
  (raw_text) @injection.content)
  (#eq? @_tag "style")
  (#not-lua-match? @_start_tag "%slang%s*=")
  (#set! injection.language "css"))

((element
  (start_tag
    (tag_name) @_tag
    (attribute
      (attribute_name) @_lang
      (quoted_attribute_value
        (attribute_value) @injection.language)))
  (raw_text) @injection.content)
  (#eq? @_tag "style")
  (#eq? @_lang "lang"))

((attribute
  (attribute_name) @_style_name
  (quoted_attribute_value
    (attribute_value) @injection.content))
  (#eq? @_style_name "style")
  (#set! injection.language "css"))

(element
  (start_tag
    (tag_name) @_tag
    (#eq? @_tag "input")
    (attribute
      (attribute_name) @_attr
      [
        (quoted_attribute_value
          (attribute_value) @injection.content)
        (attribute_value) @injection.content
      ]
      (#eq? @_attr "pattern")))
  (#set! injection.language "regex"))

(attribute
  (attribute_name) @_name
  (#lua-match? @_name "^on[a-z]+$")
  (quoted_attribute_value
    (attribute_value) @injection.content)
  (#set! injection.language "javascript"))

((expression
  content: (js) @injection.content)
  (#set! injection.language "javascript"))

((expression
  content: (ts) @injection.content)
  (#set! injection.language "typescript"))

((shorthand_attribute
  content: (js) @injection.content)
  (#set! injection.language "javascript"))

((shorthand_attribute
  content: (ts) @injection.content)
  (#set! injection.language "typescript"))

((expression_value
  content: (js) @injection.content)
  (#set! injection.language "javascript"))

((expression_value
  content: (ts) @injection.content)
  (#set! injection.language "typescript"))

((pattern
  content: (js) @injection.content)
  (#set! injection.language "javascript"))

((pattern
  content: (ts) @injection.content)
  (#set! injection.language "typescript"))

((snippet_type_parameters) @injection.content
  (#set! injection.language "typescript"))
