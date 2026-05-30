filetypes = require("tree-sitter-manager.filetypes")

for lang, ft in pairs(filetypes) do
    vim.treesitter.language.register(lang, ft)
end

-- Extensions that Neovim does not detect natively.
vim.filetype.add({
    extension = {
        uc = "ucode",
    },
})
