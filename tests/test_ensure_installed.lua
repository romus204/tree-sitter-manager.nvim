local languages = _G.languages or { "terraform", "ocaml", "helm", "python", "javascript", "razor" }
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
    parametrize = vim.iter(languages)
        :map(function(lang)
            return { lang }
        end)
        :totable(),
})

T["install"] = function(lang)
    -- wait for the parser to successfully install
    child:wait({ lang })
end

return T
