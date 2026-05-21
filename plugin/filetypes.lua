filetypes = require("tree-sitter-manager.filetypes")

for lang, ft in pairs(filetypes) do
    vim.treesitter.language.register(lang, ft)
end
