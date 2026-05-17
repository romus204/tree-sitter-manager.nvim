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
    self.start({ "-u", vim.fs.joinpath(vim.fn.stdpath("config"), "init.lua") })
    self.cmd("set nomore") -- skip hit-Enter prompts
    self.cmd("set cmdheight=10")
    self.lua([[
    config = ]] .. vim.inspect(config) .. [[
    require("tree-sitter-manager").setup(config)
    ]])
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
        self.lua("config." .. opt .. " = " .. vim.inspect(val))
        self.config[opt] = val
    end
    self.lua([[require("tree-sitter-manager").setup(config)]])
    return vim.deepcopy(self.config, true)
end

function M:parser_wait(languages, timeout, interval)
    self.lua([[
    local util = require("tree-sitter-manager.util")
    local success, reason = vim.wait(]] .. (timeout or 60000) .. [[, function()
        for _, lang in ipairs(]] .. vim.inspect(languages) .. [[) do
            if not vim.uv.fs_stat(util.ppath(lang)) then return false end
        end
        return true
    end, ]] .. (interval or 100) .. [[)
    _G.success = success
    _G.reason = reason
    ]])
    local success = self.lua_get("_G.success")
    local reason = self.lua_get("_G.reason")
    if not success then
        if -1 == reason then
            error("timeout: installing treesitter")
        end
        if -2 == reason then
            error("interrupt: installing treesitter")
        end
    end
end

return M
