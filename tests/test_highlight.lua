local languages = _G.languages or { "tsv", "tsx" }

local T = new_set({
    hooks = {
        pre_once = function()
            child.setup({ highlight = true })
        end,
    },
    parametrize = parametrize(vim.iter(languages):map(vim.treesitter.language.get_filetypes):flatten():totable()),
})

T["before_install"] = function(ft)
    -- no highlighter before installation
    child.cmd("e name." .. ft .. "|se ft=" .. ft)
    eq(false, child.lua_get("nil ~= vim.treesitter.highlighter.active[vim.fn.bufnr()]"))
end

T["after_install"] = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child.lua("installer.install(" .. vim.inspect(languages) .. ")")
            child.wait(languages)
        end,
    },
})
T["after_install"]["new"] = function(ft)
    if util.is_only_query(ft) then
        MiniTest.skip("only query")
    end
    -- highlighter is active for new buffers
    child.cmd("enew|set ft=" .. ft)
    eq(true, child.lua_get("nil ~= vim.treesitter.highlighter.active[vim.fn.bufnr()]"))
end
T["after_install"]["old"] = function(ft)
    if util.is_only_query(ft) then
        MiniTest.skip("only query")
    end
    -- highlighter is active even for existing buffers
    child.cmd("b name." .. ft)
    eq(true, child.lua_get("nil ~= vim.treesitter.highlighter.active[vim.fn.bufnr()]"))
end

T["nohighlight"] = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child.stop()
            child.setup({ highlight = true, nohighlight = languages })
        end,
    },
})
T["nohighlight"]["fails"] = function(ft)
    -- expect no highlighting for any languages
    child.cmd("enew|set ft=" .. ft)
    eq(false, child.lua_get("nil ~= vim.treesitter.highlighter.active[vim.fn.bufnr()]"))
end

return T
