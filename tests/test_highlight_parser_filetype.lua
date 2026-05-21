local languages = { "csv", "tsv", "starlark", "python", "javascript" }
if vim.env.LANGUAGES then
    languages = vim.split(vim.env.LANGUAGES, " ")
end

local child = require("tests.child")
local filetypes = require("tree-sitter-manager.filetypes")
local eq = MiniTest.expect.equality
local neq = MiniTest.expect.no_equality

local T = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child:setup()
            child:update_config({ ensure_installed = languages })
            child:parser_wait(languages)
        end,
        post_once = function()
            child:cleanup()
        end,
    },
})

for _, lang in ipairs(languages) do
    local fts = vim.deepcopy(filetypes[lang] or {})
    table.insert(fts, lang)
    for _, ft in ipairs(fts) do
        T["autocmd-" .. lang .. "-" .. ft] = function()
            require("tree-sitter-manager").setup({
                auto_install = true,
                highlight = true,
            })
            local autocmds = vim.api.nvim_get_autocmds({
                event = "FileType",
                pattern = ft,
            })
            local anymatches = vim.iter(autocmds):any(function(autocmd)
                return autocmd.desc == "Auto-enable treesitter for installed parsers"
            end)
            eq(true, anymatches)
        end
    end
end

return T
