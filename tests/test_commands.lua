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
    -- edit revision to FETCH_HEAD~
    child:update({
        languages = vim.iter(languages):fold({}, function(acc, lang)
            local info = util.get_repo_info(lang)
            info.revision = "0"
            acc[lang] = info
            return acc
        end),
    })
    child.cmd("TSUpdate " .. table.concat(languages, " "))
    child:wait(languages)
end

T["TSUninstall"] = function()
    child.cmd("TSUninstall " .. table.concat(languages, " "))
    child.restart()
    child:fails(languages)
end

return T
