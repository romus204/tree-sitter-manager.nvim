local languages = _G.languages or { "terraform", "ocaml", "helm" }
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
    parametrize = vim.iter(languages):fold({}, function(acc, lang)
        table.insert(acc, { lang })
        return acc
    end),
})

T["bundled_queries"] = function(lang)
    child:check_installed({ lang })
end

return T
