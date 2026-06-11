local languages = _G.languages or { "tsv", "javascript" }

local T = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child:setup({ highlight = true })
        end,
        post_once = function()
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

T["before_install"] = function(lang, ft)
    -- no highlighter before installation
    child.cmd("e " .. lang .. "." .. ft .. "|set ft=" .. ft)
    eq(ft, child.lua_get("vim.o.filetype"))
    eq(false, child.lua_get("nil ~= vim.treesitter.highlighter.active[vim.fn.bufnr()]"))
end

T["after_install"] = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child.lua("installer.install(" .. vim.inspect(languages) .. ")")
            child:wait(languages)
        end,
    },
})
T["after_install"]["new"] = function(lang, ft)
    -- highlighter is active for new buffers
    child.cmd("enew|set ft=" .. ft)
    eq(true, child.lua_get("nil ~= vim.treesitter.highlighter.active[vim.fn.bufnr()]"))
end
T["after_install"]["old"] = function(lang, ft)
    -- highlighter is active even for existing buffers
    child.cmd("b " .. lang .. "." .. ft)
    eq(true, child.lua_get("nil ~= vim.treesitter.highlighter.active[vim.fn.bufnr()]"))
end

T["nohighlight"] = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child.stop()
            child:setup({ highlight = true, nohighlight = languages })
        end,
    },
})
T["nohighlight"]["fails"] = function(lang, ft)
    -- expect no highlighting for any languages
    child.cmd("enew|set ft=" .. ft)
    eq(false, child.lua_get("nil ~= vim.treesitter.highlighter.active[vim.fn.bufnr()]"))
end

return T
