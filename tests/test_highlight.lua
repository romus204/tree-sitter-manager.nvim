local languages = { "csv", "tsv", "starlark", "python", "javascript", "razor" }
if vim.env.LANGUAGES then
    languages = vim.split(vim.env.LANGUAGES, " ")
end
local filetypes = require("tree-sitter-manager.filetypes")
local child = require("tests.child")
local eq = MiniTest.expect.equality
local parametrize = vim.iter(languages):fold({}, function(acc, lang)
    table.insert(acc, { lang, lang })
    for _, ft in ipairs(filetypes[lang] or {}) do
        table.insert(acc, { lang, ft })
    end
    return acc
end)

local T = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child:setup({ auto_install = false, highlight = true })
        end,
        post_case = function()
            child.cmd("set ft=")
        end,
        post_once = function()
            child:cleanup()
        end,
    },
    parametrize = parametrize,
})

T["before_install"] = function(lang, ft)
    child.cmd("enew|set ft=" .. ft)
    eq(true, child.lua_get("nil == vim.treesitter.highlighter.active[vim.fn.bufnr()]"))
end

T["after_install"] = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child:update_config({ ensure_installed = languages })
            child:parser_wait(languages)
        end,
    },
})
T["after_install"]["highlight"] = function(lang, ft)
    child.cmd("enew|set ft=" .. ft)
    eq(true, child.lua_get("nil ~= vim.treesitter.highlighter.active[vim.fn.bufnr()]"))
end

return T
