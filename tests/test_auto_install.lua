local languages = _G.languages or { "tsv", "tsx" }

local T = new_set({
    parametrize = parametrize(vim.iter(languages):map(vim.treesitter.language.get_filetypes):flatten():totable()),
})

T["noauto_install"] = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.setup({ auto_install = true, noauto_install = languages })
        end,
    },
})
T["noauto_install"]["works"] = function(ft)
    child.cmd("se ft=" .. ft)
    er(function()
        local lang = vim.treesitter.language.get_lang(ft)
        child.wait(lang)
    end, "installation not started")
end

T["auto_install"] = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.setup({ auto_install = true, noauto_install = {} })
        end,
    },
})
T["auto_install"]["works"] = function(ft)
    child.cmd("se ft=" .. ft)
    local lang = vim.treesitter.language.get_lang(ft)
    child.wait(lang)
    child.works(lang)
end

return T
