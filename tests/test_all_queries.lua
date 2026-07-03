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
    parametrize = vim.iter(languages)
        :map(function(lang)
            local paths = vim.fn.glob("runtime/queries/" .. lang .. "/*.scm", true, true)
            local queries = vim.iter(paths):map(function(path)
                return vim.fn.fnamemodify(path, ":t:r")
            end)
            return vim.iter({ "parser", unpack(queries:totable()) })
                :map(function(query)
                    return { lang, query }
                end)
                :totable()
        end)
        :flatten()
        :totable(),
})

T.pass = function(lang, query)
    if fail_parser[lang] then
        MiniTest.skip("failed parser")
    end
    fail_parser[lang] = not query
    child.wait(lang)
    child.works(lang, query)
    fail_parser[lang] = nil
end

return T
