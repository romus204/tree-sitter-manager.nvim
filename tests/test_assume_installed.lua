local languages = languages or { "c", "markdown" }

local T = new_set({
    hooks = {
        pre_once = function()
            child.setup({ assume_installed = languages })
        end,
    },
})

T.assume_installed = function()
    local err = child.install(languages, 0, true)
    eq(true, not err or 0 <= vim.fn.match(err, [[^\v([^\n]*installation not started[^\n]*\n?)*$]]), err)
end

T.dependants = function()
    local dependants = vim.iter(languages)
        :map(function(lang)
            return vim.iter(config.languages):find(function(other)
                return util.notin(languages)(other) and util.isin(util.get_requires(other))(lang)
            end)
        end)
        :totable()

    if #dependants == 0 then
        MiniTest.skip("no dependants")
    end
    child.install(dependants)
end

return T
