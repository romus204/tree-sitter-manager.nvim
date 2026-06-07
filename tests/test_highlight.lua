local languages = _G.languages or { "csv", "tsv", "starlark", "python", "javascript", "razor" }
local filetypes = require("tree-sitter-manager.filetypes")
local child = require("tests.child")

local T = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child:setup({ highlight = true })
        end,
        post_case = function()
            child.cmd("set ft=")
        end,
        post_once = function()
            child:cleanup()
        end,
    },
    parametrize = vim.iter(languages):fold({}, function(acc, lang)
        table.insert(acc, { lang, lang })
        for _, ft in ipairs(filetypes[lang] or {}) do
            table.insert(acc, { lang, ft })
        end
        return acc
    end),
})

T["before_install"] = function(lang, ft)
    -- no highlighter before installation
    child.cmd("e " .. lang .. "." .. ft .. "|set ft=" .. ft)
    eq(true, child.lua_get("nil == vim.treesitter.highlighter.active[vim.fn.bufnr()]"))
end

T["after_install"] = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child.cmd("TSInstall " .. table.concat(languages, " "))
            child:wait(languages)
        end,
    },
})
T["after_install"]["new"] = function(lang, ft)
    -- highlighter is active for new buffers
    child.cmd("enew|set ft=" .. ft)
    eq(true, child.lua_get("nil ~= vim.treesitter.highlighter.active[vim.fn.bufnr()]"))
end
T["after_install"]["old"] = function(lang, ft)
    -- highlighter is active even for existing buffers
    child.cmd("b " .. lang .. "." .. ft)
    eq(true, child.lua_get("nil ~= vim.treesitter.highlighter.active[vim.fn.bufnr()]"))
end

return T
