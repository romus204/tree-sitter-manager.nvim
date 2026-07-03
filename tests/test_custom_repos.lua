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
T["local"].fails = function()
    child.cmd("TSInstall console")
    er(function()
        child.wait("console")
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
T.generate.works = function()
    child.cmd("TSInstall perl")
    child.wait("perl")
    child.works("perl")
end
T.generate.fails = function()
    child.lua("config.effective_repos.perl.install_info.generate = false")
    child.cmd("TSInstall perl")
    er(function()
        child.wait("perl")
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
T.location.works = function()
    child.cmd("TSInstall prolog")
    child.wait("prolog")
    child.works("prolog")
end
T.location.fails = function()
    child.lua("config.effective_repos.prolog.install_info.location = nil")
    child.cmd("TSInstall prolog")
    er(function()
        child.wait("prolog")
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
T.queries.works = function()
    child.cmd("TSInstall matlab")
    child.wait("matlab")
    child.works("matlab")
end
T.queries.fails = function()
    child.lua("config.effective_repos.matlab.install_info.queries = 'queries'")
    child.cmd("TSInstall matlab")
    child.wait("matlab")
    child.fails("matlab")
end

return T
