(template_tag
  (type_param) @template.param)

(param_tag
  type: (_)? @param.type
  name: (_)? @param.name
  description: (description)? @param.description)

(returns_tag
  type: (type_expression) @returns.type
  description: (description)? @returns.description)

(throws_tag
  type: (type_expression)? @throws.type
  description: (description)? @throws.description)

(typedef_tag
  type: (type_expression)? @typedef.type
  name: (type_identifier) @typedef.name)

(type_tag
  type: (type_expression) @type.type)
