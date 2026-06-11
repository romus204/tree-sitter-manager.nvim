local M = MiniTest.new_child_neovim()

function M:setup(config)
    self.name = MiniTest.current.case and MiniTest.current.case.desc[1] or "tests/interactive_session"
    local path = vim.fs.joinpath(vim.fn.stdpath("data"), self.name)
    local parser_dir = vim.fs.joinpath(path, "parser")
    local query_dir = vim.fs.joinpath(path, "queries")
    vim.fs.rm(parser_dir, { recursive = true, force = true })
    vim.fs.rm(query_dir, { recursive = true, force = true })
    tsm.setup({ parser_dir = parser_dir, query_dir = query_dir })
    self.config = config or self.config or {}
    self.config.parser_dir = parser_dir
    self.config.query_dir = query_dir
    self.restart({
        "-u",
        vim.fs.joinpath(vim.fn.stdpath("config"), "init.lua"),
        "+set nomore cmdheight=100", -- skip hit-enter prompts
        "+lua tsm.setup(" .. vim.inspect(self.config) .. ")",
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

function M:wait(languages, timeout)
    if type(languages) == "string" then
        languages = { languages }
    end
    timeout = timeout or 60000
    self.lua([[
    status = installer.status
    languages = ]] .. vim.inspect(languages) .. [[
    success, reason = vim.wait(
        ]] .. timeout .. [[,
        function()
            languages = vim.tbl_filter(function(lang)
                return status[lang] and status[lang].installing
            end, languages)
            return #languages == 0
        end,
        50
    )
    ]])
    local success = self.lua_get("success")
    local reason = self.lua_get("reason")
    local langs = self.lua_get("languages")
    local status = self.lua_get("status")
    if not success then
        if -1 == reason then
            reason = "timeout"
        elseif -2 == reason then
            reason = "interrupt"
        end
        error(reason .. " installing parser " .. vim.inspect(langs))
    end
    local err = "\n"
    for _, lang in ipairs(languages) do
        if not self.lua_get("util.is_installed('" .. lang .. "')") then
            if not status[lang] then
                err = err .. "installation not started for " .. lang .. "\n"
            elseif not status[lang].ok then
                err = err .. (status[lang].error or "installation failed for " .. lang) .. "\n"
            end
        end
    end
    if err ~= "\n" then
        error(err)
    end
end

function M:works(languages, query)
    if type(languages) == "string" then
        languages = { languages }
    end
    query = query or "highlights"
    for _, lang in ipairs(languages) do
        ner(function()
            self.lua("vim.treesitter.get_string_parser('', '" .. lang .. "')")
        end)
        eq(true, self.lua_get("nil ~= vim.treesitter.query.get('" .. lang .. "', '" .. query .. "')"))
    end
end

function M:fails(languages, query)
    if type(languages) == "string" then
        languages = { languages }
    end
    query = query or "highlights"
    for _, lang in ipairs(languages) do
        er(function()
            self.lua("vim.treesitter.get_string_parser('', '" .. lang .. "')")
        end)
        eq(false, self.lua_get("nil ~= vim.treesitter.query.get('" .. lang .. "', '" .. query .. "')"))
    end
end

return M
