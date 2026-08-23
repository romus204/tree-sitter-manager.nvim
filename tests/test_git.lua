local T = new_set({ hooks = { pre_case = child.setup, post_case = child.cleanup } })

T.revision = new_set()
T.revision.pass = function()
    local install_info = {
        revision = "64b56832c2cffe41758f28e05c756a3a98d16f41",
        url = "https://github.com/tree-sitter-grammars/tree-sitter-toml",
    }
    child.setup({ languages = { toml = { install_info = install_info } } })
    child.install("toml")
end
T.revision.fail = function()
    local install_info = {
        revision = "_",
        url = "https://github.com/tree-sitter-grammars/tree-sitter-toml",
    }
    child.setup({ languages = { toml = { install_info = install_info } } })
    er(function()
        child.install("toml")
    end, "revision _ not found")
end
T.revision.pre_2_49 = new_set({
    hooks = {
        pre_case = function()
            -- simulate git pre 2.49
            child.lua([[
            local system = vim.system
            vim.system = function(cmd, ...)
                if type(cmd) == "table" and cmd[1] == "git" and cmd[2] == "version" then
                    return {
                        wait = function(self, ...)
                            return {
                                code = 0,
                                signal = 0,
                                stdout = "git version 2.47.0\n",
                                stderr = "",
                            }
                        end,
                    }
                end
                return system(cmd, ...)
            end
            ]])
            local version = { child.lua_get('util.run({"git","version"}):wait().output'):match("(%d+)%.(%d+)%.(%d+)") }
            local major, minor, patch = unpack(vim.iter(version):map(tonumber):totable())
            eq(true, major < 2 or major == 2 and minor < 49)
        end,
    },
}, { pass = T.revision.pass, fail = T.revision.fail })

T.branch = new_set()
T.branch.pass = function()
    local install_info = {
        branch = "master",
        url = "https://github.com/tree-sitter-grammars/tree-sitter-toml",
    }
    child.setup({ languages = { toml = { install_info = install_info } } })
    child.install("toml")
end
T.branch.fail = function()
    local install_info = {
        branch = "_",
        url = "https://github.com/tree-sitter-grammars/tree-sitter-toml",
    }
    child.setup({ languages = { toml = { install_info = install_info } } })
    er(function()
        child.install("toml")
    end, "branch _ not found")
end

T.norev_nobra = new_set()
T.norev_nobra.pass = function()
    local install_info = {
        url = "https://github.com/tree-sitter-grammars/tree-sitter-toml",
    }
    child.setup({ languages = { toml = { install_info = install_info } } })
    child.install("toml")
end

T.GIT_WORK_TREE = function()
    child.cmd("let $GIT_WORK_TREE = '.'")
    child.install("toml")
end

return T
