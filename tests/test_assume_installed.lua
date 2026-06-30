local languages = _G.languages or { "c", "markdown" }

local T = new_set({
    hooks = {
        pre_once = function()
            child.setup({ assume_installed = languages })
        end,
    },
})

T["assume_installed"] = function()
    child.cmd("TSInstall " .. table.concat(languages, " "))
    child.wait(languages, 0)
end

T["dependants"] = function()
    local dependants = vim.iter(languages):fold({}, function(acc, lang)
        for _, dep in ipairs(config.languages) do
            if vim.list_contains(util.get_requires(dep), lang) then
                table.insert(acc, dep)
                return acc
            end
        end
        return acc
    end)
    if #dependants == 0 then
        MiniTest.skip("no dependants")
    end
    child.cmd("TSInstall " .. table.concat(dependants, " "))
    child.wait(dependants)
end

return T
