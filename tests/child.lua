local M = MiniTest.new_child_neovim()

function M.setup(config)
    M.name = MiniTest.current.case and MiniTest.current.case.desc[1] or "tests/interactive_session"
    local path = vim.fs.joinpath(vim.fn.stdpath("data"), M.name)
    local parser_dir = vim.fs.joinpath(path, "parser")
    local query_dir = vim.fs.joinpath(path, "queries")
    tsm.setup({ parser_dir = parser_dir, query_dir = query_dir })
    M.config = config or M.config or {}
    M.config.parser_dir = parser_dir
    M.config.query_dir = query_dir
    M.restart({
        "-u",
        vim.fs.joinpath(vim.fn.stdpath("config"), "init.lua"),
        "+set nomore cmdheight=100", -- skip hit-enter prompts
        "+lua tsm.setup(" .. vim.inspect(M.config) .. ")",
    })
    M.timeout = {}
end

function M.cleanup()
    M.stop()
    local path = vim.fs.joinpath(vim.fn.stdpath("data"), M.name)
    local parser_dir = vim.fs.joinpath(path, "parser")
    local query_dir = vim.fs.joinpath(path, "queries")
    vim.fs.rm(parser_dir, { recursive = true, force = true })
    vim.fs.rm(query_dir, { recursive = true, force = true })
end

function M.wait(languages, timeout, return_error)
    languages = type(languages) == "string" and { languages } or { unpack(languages) }
    -- add dependencies
    vim.list.unique(vim.list_extend(languages, vim.iter(languages):map(util.get_requires):flatten():totable()))
    -- don't wait for languages already timed out
    languages = vim.iter(languages):filter(util.no(util.get(M.timeout))):totable()
    timeout = timeout or 60000
    M.lua([[
    success, reason = vim.wait(
        ]] .. timeout .. [[,
        function()
            return not vim.iter(]] .. vim.inspect(languages) .. [[):any(util.get(installer.installing))
        end,
        1000
    )
    ]])

    local err
    if not M.lua_get("success") then
        local reason = M.lua_get("reason")
        local failed =
            M.lua_get("vim.iter(" .. vim.inspect(languages) .. "):filter(util.get(installer.installing)):totable()")
        if reason == -1 then
            for _, lang in ipairs(failed) do
                M.timeout[lang] = true
            end
        end
        err = (reason == -1) and "timeout " or (reason == -2) and "interrupt " or ""
        err = err .. vim.inspect(failed)
    else
        err = ""
        local status = M.lua_get("installer.status")
        for _, lang in ipairs(languages) do
            if M.lua_get("util.is_installed('" .. lang .. "')") then
            elseif not status[lang] then
                err = err .. lang .. ": installation not started\n"
            elseif not status[lang].ok then
                local e = status[lang].error
                err = err .. (vim.startswith(e, lang) and e or lang .. ": " .. e) .. "\n"
            end
        end
        err = err ~= "" and err or nil
    end

    if return_error then
        return err
    elseif err then
        error("\n" .. err)
    end
end

function M.works(languages, query)
    languages = type(languages) == "string" and { languages } or languages
    query = query or "highlights"
    for _, lang in ipairs(languages) do
        if not util.is_only_query(lang) then
            ner(function()
                M.lua("vim.treesitter.get_string_parser('', '" .. lang .. "')")
            end)
            eq(true, M.lua_get("nil ~= vim.treesitter.query.get('" .. lang .. "', '" .. query .. "')"))
        end
    end
end

function M.fails(languages, query)
    if type(languages) == "string" then
        languages = { languages }
    end
    query = query or "highlights"
    for _, lang in ipairs(languages) do
        local parser_works = pcall(M.lua, "vim.treesitter.get_string_parser('', '" .. lang .. "')")
        local query_works = M.lua_get("nil ~= vim.treesitter.query.get('" .. lang .. "', '" .. query .. "')")
        eq(false, parser_works and query_works)
    end
end

return M
