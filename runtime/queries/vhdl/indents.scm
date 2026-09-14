[
  ; Design units
  (entity_declaration)
  (architecture_definition)
  (package_declaration)
  (package_definition)
  (component_declaration)

  ; Interface and association lists
  (port_clause)
  (generic_clause)
  (association_list)
  (parenthesis_group)

  ; Concurrent statements
  (process_statement)
  (block_statement)
  (component_instantiation_statement)
  (for_generate_statement)
  (if_generate_statement)
  (case_generate_statement)
  (case_generate_alternative)

  ; Sequential statements
  (if_statement_block)
  (case_statement)
  (case_statement_alternative)
  (loop_statement)

  ; Subprogram and types
  (subprogram_definition)
  (record_type_definition)
] @indent.begin

[
  "begin"
  "elsif"
  "else"
  (end_entity)
  (end_architecture)
  (end_package)
  (end_package_body)
  (end_component)
  (end_process)
  (end_block)
  (end_generate)
  (end_if)
  (end_case)
  (end_loop)
  (end_record)
  (subprogram_end)
] @indent.branch

(port_clause
  ")" @indent.branch)

(generic_clause
  ")" @indent.branch)

(association_list
  ")" @indent.branch)

(parenthesis_group
  ")" @indent.branch)
