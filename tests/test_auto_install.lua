local languages = _G.languages or { "tsv", "javascript" }
local filetypes = require("tree-sitter-manager.filetypes")
local util = require("tree-sitter-manager.util")
local child = require("tests.child")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child:setup({ auto_install = true, noauto_install = languages })
        end,
        post_case = function()
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

T["noauto_install"] = function(lang, ft)
    child.cmd("se ft=" .. ft)
    -- expect timeout because no parser is installed
    er(function()
        child:wait({ lang }, 4000)
    end, "timeout")
end

T["auto_install"] = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child:update({ noauto_install = {} })
        end,
    },
})
T["auto_install"]["success"] = function(lang, ft)
    child.cmd("se ft=" .. ft)
    -- wait for the parser to successfully install
    child:wait({ lang }, 4000)
end

return T
