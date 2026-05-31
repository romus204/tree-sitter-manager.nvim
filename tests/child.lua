M = MiniTest.new_child_neovim()

function M:setup(config)
    self.name = MiniTest.current.case.desc[1]
    local path = vim.fs.joinpath(vim.fn.stdpath("data"), self.name)
    local parser_dir = vim.fs.joinpath(path, "parser")
    local query_dir = vim.fs.joinpath(path, "queries")
    vim.fs.rm(parser_dir, { recursive = true, force = true })
    vim.fs.rm(query_dir, { recursive = true, force = true })
    require("tree-sitter-manager").setup({ parser_dir = parser_dir, query_dir = query_dir })
    self.config = config or {}
    self.config.parser_dir = parser_dir
    self.config.query_dir = query_dir
    self.start({
        "-u",
        vim.fs.joinpath(vim.fn.stdpath("config"), "init.lua"),
        "+set nomore cmdheight=100", -- skip hit-enter prompts
        "+lua require('tree-sitter-manager').setup(" .. vim.inspect(self.config) .. ")",
    })
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
    self.config = vim.tbl_deep_extend("force", self.config, config)
    self.lua("require('tree-sitter-manager').setup(" .. vim.inspect(self.config) .. ")")
    return vim.deepcopy(self.config, true)
end

function M:parser_wait(languages, timeout)
    timeout = timeout or 60000
    self.lua([[
    local util = require("tree-sitter-manager.util")
    languages = ]] .. vim.inspect(languages) .. [[
    success, reason = vim.wait(
        ]] .. timeout .. [[,
        function()
            languages = vim.tbl_filter(function(lang)
                return not vim.uv.fs_stat(util.ppath(lang))
            end, languages)
            return #languages == 0
        end,
        100
    )
    vim.wait(100)
    ]])
    local success = self.lua_get("success")
    local reason = self.lua_get("reason")
    local langs = self.lua_get("languages")
    if not success then
        if -1 == reason then
            reason = "timeout"
        elseif -2 == reason then
            reason = "interrupt"
        end
        error(reason .. " installing parser " .. vim.inspect(langs))
    end
end

function M:check_installed(languages, timeout)
    self:parser_wait(languages, timeout)
    for _, lang in ipairs(languages) do
        MiniTest.expect.no_error(function()
            self.lua("vim.treesitter.get_string_parser('', '" .. lang .. "')")
        end)
        self.lua("query = vim.treesitter.query.get_files('" .. lang .. "', 'highlights')")
        MiniTest.expect.no_equality(vim.NIL, self.lua_get("query"))
    end
end

function M:check_not_installed(languages)
    for _, lang in ipairs(languages) do
        MiniTest.expect.error(function()
            self.lua("vim.treesitter.get_string_parser('', '" .. lang .. "')")
        end)
        self.lua("query = vim.treesitter.query.get('" .. lang .. "', 'highlights')")
        MiniTest.expect.equality(vim.NIL, self.lua_get("query"))
    end
end

return M
