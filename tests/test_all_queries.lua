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
    parametrize = vim.iter(languages)
        :map(function(lang)
            local paths = vim.fn.glob("runtime/queries/" .. lang .. "/*.scm", true, true)
            local queries = vim.iter(paths):map(function(path)
                return vim.fn.fnamemodify(path, ":t:r")
            end)
            return queries
                :map(function(query)
                    return { lang, query }
                end)
                :totable()
        end)
        :flatten()
        :totable(),
})

T["ensure_installed"] = function(lang, query)
    -- wait for the parser to successfully install
    child.wait(lang, 120000)
    child.works(lang, query)
end

return T
