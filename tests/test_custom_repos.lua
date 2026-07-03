local T = new_set({
    hooks = {
        pre_case = function()
            if _G.languages then
                MiniTest.skip("skip smoke tests")
            end
        end,
        post_case = child.cleanup,
    },
})

T["local"] = MiniTest.new_set({
    hooks = {
        pre_case = function()
            local info = {
                url = "/home/sroeca/src/pappasam/tree-sitter-console",
                branch = "main",
                queries = "queries",
            }
            child.setup({ languages = { console = { install_info = info } } })
        end,
    },
})
T["local"].fail = function()
    er(function()
        child.install("console")
    end, "does not exist")
end

T.generate = MiniTest.new_set({
    hooks = {
        pre_case = function()
            local info = {
                generate = true,
                revision = "c3e17b31179bf8f658c9f37c7a3ea6a202212d5a",
                url = "https://github.com/tree-sitter-perl/tree-sitter-perl",
            }
            child.setup({ languages = { perl = { install_info = info } } })
        end,
    },
})
T.generate.pass = function()
    child.install("perl")
    child.works("perl", "parser")
end
T.generate.fail = function()
    child.lua("config.effective_repos.perl.install_info.generate = false")
    er(function()
        child.install("perl")
    end, "Failed to compile")
end

T.location = MiniTest.new_set({
    hooks = {
        pre_case = function()
            local info = {
                location = "grammars/prolog",
                revision = "d8d415f6a1cf80ca138524bcc395810b176d40fa",
                url = "https://github.com/foxyseta/tree-sitter-prolog",
            }
            child.setup({ languages = { perl = { install_info = info } } })
        end,
    },
})
T.location.pass = function()
    child.install("prolog")
    child.works("prolog", "parser")
end
T.location.fail = function()
    child.lua("config.effective_repos.prolog.install_info.location = nil")
    er(function()
        child.install("prolog")
    end, "Failed to compile")
end

T.queries = MiniTest.new_set({
    hooks = {
        pre_case = function()
            local info = {
                revision = "c9ef947ec67fb6b500d5def4f5e09b56990a9f91",
                url = "https://github.com/acristoffers/tree-sitter-matlab",
                queries = "queries/neovim",
            }
            child.setup({ languages = { perl = { install_info = info } } })
        end,
    },
})
T.queries.pass = function()
    child.install("matlab")
    child.works("matlab", "highlights")
end
T.queries.fail = function()
    child.lua("config.effective_repos.matlab.install_info.queries = 'queries'")
    child.install("matlab")
    child.fails("matlab", "highlights")
end

return T
