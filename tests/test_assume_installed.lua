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
    local err = child.wait(languages, 0, true)
    eq(true, err == nil or 0 <= vim.fn.match(err, [[^\v([^\n]*installation not started[^\n]*\n?)*$]]))
end

T["dependants"] = function()
    local dependants = vim.iter(languages)
        :map(function(lang)
            return vim.iter(config.languages):find(function(other)
                return not util.isin(languages)(other) and util.isin(util.get_requires(other))(lang)
            end)
        end)
        :totable()

    if #dependants == 0 then
        MiniTest.skip("no dependants")
    end
    child.cmd("TSInstall " .. table.concat(dependants, " "))
    child.wait(dependants)
end

return T
