local child = require("tests.child")

local T = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child:setup()
        end,
        pre_case = function()
            child.restart()
        end,
        post_case = function()
            child:cleanup()
        end,
    },
})

T["revision"] = function()
    local lang = _G.languages or { "odin", "ocamllex", "ocaml_interface" }
    child:update_config({ ensure_installed = lang })
    child:check_installed(lang, 100000)
end

T["branch_revision"] = function()
    local lang = _G.languages or { "sql" }
    child:update_config({ ensure_installed = lang })
    child:check_installed(lang)
end

T["branch"] = function()
    local lang = _G.languages or { "sql" }
    local base_repos = require("tree-sitter-manager.config").base_repos
    child:update_config({
        ensure_installed = lang,
        languages = vim.iter(lang):fold({}, function(acc, l)
            acc[l] = {
                install_info = {
                    branch = "main",
                    url = base_repos[l].install_info.url,
                },
            }
        end),
    })
    child:check_installed(lang)
end

T["no_branch_no_rev"] = function()
    local lang = _G.languages or { "sql" }
    local base_repos = require("tree-sitter-manager.config").base_repos
    child:update_config({
        ensure_installed = lang,
        languages = vim.iter(lang):fold({}, function(acc, l)
            acc[l] = {
                install_info = {
                    url = base_repos[l].install_info.url,
                },
            }
        end),
    })
    child:check_installed(lang)
end

T["pre_2.49.0"] = MiniTest.new_set({
    hooks = {
        pre_once = function()
            child.restart()
            child.lua([[
            system = vim.system
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
        end,
        post_once = function()
            child:cleanup()
        end,
    },
})
T["pre_2.49.0"]["revision"] = function()
    local lang = _G.languages or { "php", "perl", "pem" }
    child:update_config({ ensure_installed = lang })
    child:check_installed(lang)
end

return T
