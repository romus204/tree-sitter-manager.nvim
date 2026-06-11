local languages = _G.languages or { "tsv", "javascript" }

local T = MiniTest.new_set({
    hooks = {
        pre_once = function()
            if vim.env.LANGUAGES == "all" then
                child:setup({ ensure_installed = "all" })
            else
                child:setup({ ensure_installed = languages })
            end
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

T["ensure_installed"] = function(lang)
    -- wait for the parser to successfully install
    child:wait(lang)
    child:works(lang)
end

return T
