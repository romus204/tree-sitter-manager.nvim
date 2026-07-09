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
        post_once = function()
            local reports = vim.defaulttable(function()
                return ""
            end)
            for _, case in ipairs(MiniTest.current.all_cases) do
                if case.desc[1] == "tests/test_all_queries.lua" then
                    local lang = unpack(case.args)
                    reports[lang] = reports[lang] .. table.concat(case.exec.fails, "\n")
                end
            end

            local pass, fail = {}, {}
            for lang, report in pairs(reports) do
                if report == "" then
                    table.insert(pass, lang)
                else
                    fail[lang] = report
                end
            end

            vim.print("\n" .. vim.inspect(pass) .. "\n")
            vim.print("\n" .. vim.inspect(fail) .. "\n")
        end,
    },
    parametrize = vim.iter(languages)
        :map(function(lang)
            if util.is_only_query(lang) then
                return { { lang } }
            end
            local paths = vim.fn.glob("runtime/queries/" .. lang .. "/*.scm", true, true)
            local queries = vim.iter(paths)
                :map(function(path)
                    return { lang, vim.fn.fnamemodify(path, ":t:r") }
                end)
                :totable()
            table.insert(queries, 1, { lang, "parser" })
            return queries
        end)
        :flatten()
        :totable(),
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
