filetypes = require("tree-sitter-manager.filetypes")

for lang, ft in pairs(filetypes) do
    vim.treesitter.language.register(lang, ft)
end

-- Extensions that Neovim does not detect natively.
vim.filetype.add({
    extension = {
        -- .uc is used by both ucode (plain code) and ucode_tmpl (templates).
        -- Detect by content: if any line starts with a template tag opener
        -- ({%, {{, {#) the file is a template, otherwise plain ucode.
        uc = function(path, bufnr)
            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 100, false)
            for _, line in ipairs(lines) do
                if line:match("^%s*{[%%{#]") then
                    return "ucode_tmpl"
                end
            end
            return "ucode"
        end,
        utpl = "ucode_tmpl",
    },
})
