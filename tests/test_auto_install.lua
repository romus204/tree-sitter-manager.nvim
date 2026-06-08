local languages = _G.languages or { "terraform", "ocaml", "helm", "python", "javascript", "razor" }
local child = require("tests.child")

local T = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child:setup({ auto_install = true })
            for _, lang in ipairs(languages) do
                child.cmd("se ft=" .. lang)
            end
            child.cmd("se ft=")
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

T["auto_install"] = function(lang)
    -- wait for the parser to successfully install
    child:wait({ lang })
end

return T
