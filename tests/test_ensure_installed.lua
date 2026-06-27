local languages = _G.languages or { "tsv", "tsx" }

local T = new_set({
    hooks = {
        pre_once = function()
            if vim.env.LANGUAGES == "all" then
                child.setup({ ensure_installed = "all" })
            else
                child.setup({ ensure_installed = languages })
            end
        end,
    },
    parametrize = parametrize(languages),
})

T["ensure_installed"] = function(lang)
    -- wait for the parser to successfully install
    child.wait(lang)
    child.works(lang)
end

return T
