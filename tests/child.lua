M = MiniTest.new_child_neovim()

function M:setup()
    self.name = MiniTest.current.case.desc[1]
    local path = vim.fs.joinpath(vim.fn.stdpath("data"), self.name)
    local parser_dir = vim.fs.joinpath(path, "parser")
    local query_dir = vim.fs.joinpath(path, "queries")
    vim.fs.rm(parser_dir, { recursive = true, force = true })
    vim.fs.rm(query_dir, { recursive = true, force = true })
    local config = {
        parser_dir = parser_dir,
        query_dir = query_dir,
    }
    require("tree-sitter-manager").setup(config)
    self.start({
        "-u",
        vim.fs.joinpath(vim.fn.stdpath("config"), "init.lua"),
        "+set nomore cmdheight=10", -- skip hit-enter prompts
        "+lua require('tree-sitter-manager').setup(" .. vim.inspect(config) .. ")",
    })
    self.config = config
end

function M:cleanup()
    self.stop()
    local path = vim.fs.joinpath(vim.fn.stdpath("data"), self.name)
    local parser_dir = vim.fs.joinpath(path, "parser")
    local query_dir = vim.fs.joinpath(path, "queries")
    vim.fs.rm(parser_dir, { recursive = true, force = true })
    vim.fs.rm(query_dir, { recursive = true, force = true })
end

function M:update_config(config)
    for opt, val in pairs(config) do
        self.config[opt] = val
    end
    self.lua("require('tree-sitter-manager').setup(" .. vim.inspect(config) .. ")")
    return vim.deepcopy(self.config, true)
end

function M:parser_wait(languages, timeout, interval)
    timeout = timeout or 60000
    interval = interval or 100
    self.lua([[
    local util = require("tree-sitter-manager.util")
    _G.success = true
    for _, lang in ipairs(]] .. vim.inspect(languages) .. [[) do
        local success, reason = vim.wait(
            ]] .. timeout .. [[,
            function()
                return vim.uv.fs_stat(util.ppath(lang))
            end,
            ]] .. interval .. [[
        )
        if not success then
            _G.success = false
            _G.reason = reason
            _G.language = lang
            break
        end
    end
    vim.wait(500)
    ]])
    local success = self.lua_get("_G.success")
    local reason = self.lua_get("_G.reason")
    local language = self.lua_get("_G.language")
    if not success then
        if -1 == reason then
            reason = "timeout"
        elseif -2 == reason then
            reason = "interrupt"
        end
        error(reason .. ": installing parser " .. language)
    end
end

return M
