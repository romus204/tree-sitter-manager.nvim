local languages = _G.languages or { "cpp", "python", "javascript", "razor" }
local child = require("tests.child")

local T = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child:setup({ ensure_installed = languages })
        end,
        post_once = function()
            child:cleanup()
        end,
    },
    parametrize = vim.iter(languages == "all" and require("tree-sitter-manager.repos") or languages)
        :map(function(lang)
            return { lang }
        end)
        :totable(),
})

T["install"] = function(lang)
    child:parser_wait({ lang }, 600000)
end

return T
