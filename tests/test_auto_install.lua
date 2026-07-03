local languages = _G.languages or { "tsv", "tsx" }

local T = new_set({
    parametrize = parametrize(vim.iter(languages):map(vim.treesitter.language.get_filetypes):flatten():totable()),
})

T["noauto_install"] = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child.setup({ auto_install = true, noauto_install = languages })
        end,
        post_once = child.cleanup,
    },
})
T["noauto_install"]["works"] = function(ft)
    child.cmd("se ft=" .. ft)
    local lang = vim.treesitter.language.get_lang(ft)
    er(function()
        child.wait(lang, 0)
    end, "installation not started")
end

T["auto_install"] = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child.setup({ auto_install = true, noauto_install = {} })
        end,
    },
})
T["auto_install"]["works"] = function(ft)
    child.cmd("se ft=" .. ft)
    local lang = vim.treesitter.language.get_lang(ft)
    local err = child.wait(lang, 0, true)
    eq(false, err ~= nil and not err:match("timeout"))
end

return T
