local languages = _G.languages or { "tsv", "tsx" }
local fail_parser = {}

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
    parametrize = parametrize_with_queries(languages),
})

T.pass = function(lang, query)
    if util.is_only_query(lang) then
        MiniTest.skip("query dependency")
    elseif fail_parser[lang] then
        MiniTest.skip("failed parser")
    end
    fail_parser[lang] = query == "parser"
    child.wait_installed(lang)
    child.works(lang, query)
    fail_parser[lang] = false
end

return T
