local T = MiniTest.new_set({
    hooks = {
        post_case = function()
            child:cleanup()
        end,
    },
})

T["crash"] = function()
    child:setup({
        languages = {
            haskell = {
                install_info = {
                    url = "https://github.com/tree-sitter-grammars/tree-sitter-haskell",
                    revision = "7fa19f195803a77855f036ee7f49e4b22856e338",
                },
            },
        },
        ensure_installed = { "haskell" },
    })
    child:wait("haskell")
    er(function()
        child.cmd("edit tests/haskell/Main.hs")
        child.cmd("edit")
    end, "was closed by the peer")
end

T["works"] = function()
    child:setup({
        languages = {
            haskell = {
                install_info = {
                    url = "https://github.com/tree-sitter-grammars/tree-sitter-haskell",
                    revision = "98aedbd2d6947a168ba3ba3755d70b0cb6b78395",
                },
            },
        },
        ensure_installed = { "haskell" },
    })
    child:wait("haskell")
    ner(function()
        child.cmd("edit tests/haskell/Main.hs")
        child.cmd("edit")
    end)
end

return T
