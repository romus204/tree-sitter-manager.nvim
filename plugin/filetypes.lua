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
        uc = function(path)
            local f = io.open(path, "r")
            if f then
                for line in f:lines() do
                    if line:match("^%s*{[%%{#]") then
                        f:close()
                        return "ucode_tmpl"
                    end
                end
                f:close()
            end
            return "ucode"
        end,
        utpl = "ucode_tmpl",
    },
})
