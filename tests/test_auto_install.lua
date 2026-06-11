local languages = _G.languages or { "tsv", "javascript" }

local T = MiniTest.new_set({
    hooks = {
        post_case = function()
            child:cleanup()
        end,
    },
    parametrize = vim.iter(languages):fold({}, function(acc, lang)
        table.insert(acc, { lang, lang })
        for _, ft in ipairs(filetypes[lang] or {}) do
            table.insert(acc, { lang, ft })
        end
        return acc
    end),
})

T["noauto_install"] = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child:setup({ auto_install = true, noauto_install = languages })
        end,
    },
})
T["noauto_install"]["works"] = function(lang, ft)
    child.cmd("se ft=" .. ft)
    er(function()
        child:wait(lang)
    end, "installation not started")
end

T["auto_install"] = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child:setup({ auto_install = true, noauto_install = {} })
        end,
    },
})
T["auto_install"]["works"] = function(lang, ft)
    child.cmd("se ft=" .. ft)
    child:wait(lang)
    child:works(lang)
end

return T
