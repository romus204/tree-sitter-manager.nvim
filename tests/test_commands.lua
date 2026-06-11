local languages = _G.languages or { "tsv", "javascript" }

local T = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child:setup()
        end,
        post_once = function()
            child:cleanup()
        end,
    },
})

T["TSInstall"] = function()
    child.cmd("TSInstall " .. table.concat(languages, " "))
    child:wait(languages)
    child:works(languages)
end

T["TSUpdate"] = function()
    -- expect everything working before update
    child:wait(languages)
    child:works(languages)
    -- change to invalid branch
    child:setup({
        languages = vim.iter(languages):fold({}, function(acc, lang)
            local info = util.get_repo_info(lang)
            info.revision = nil
            info.branch = "not-found"
            acc[lang] = { install_info = info }
            return acc
        end),
    })
    child.cmd("TSUpdate " .. table.concat(languages, " "))
    -- expect error after update
    er(function()
        child:wait(languages)
    end, "not found")
end

T["TSUninstall"] = function()
    child.cmd("TSUninstall " .. table.concat(languages, " "))
    child.restart()
    child:fails(languages)
end

return T
