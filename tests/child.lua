---@class Child
---@field setup fun(config)
---@field cleanup function
---@field wait_installed fun(languages, timeout?, return_error?)
---@field install fun(languages, timeout?, return_error?)
---@field remove fun(languages)
---@field works fun(languages, query)
---@field fails fun(languages, query)
local M = MiniTest.new_child_neovim()

---@param config tree_sitter_manager.Config
function M.setup(config)
    M.name = MiniTest.current.case and MiniTest.current.case.desc[1] or "tests/interactive_session"
    local path = vim.fs.joinpath(vim.fn.stdpath("data"), M.name)
    local parser_dir = vim.fs.joinpath(path, "parser")
    local query_dir = vim.fs.joinpath(path, "queries")
    tsm.setup({ parser_dir = parser_dir, query_dir = query_dir })
    M.config = config or {}
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

---@param languages string[]
---@param timeout? number default 60,000 ms
---@param return_error? boolean whether to return or throw an error (default false)
---@param with_deps? boolean wait for dependencies (default true)
function M.wait_installed(languages, timeout, return_error, with_deps)
    languages = type(languages) == "string" and { languages } or { unpack(languages) }
    -- add dependencies
    if with_deps or with_deps == nil then
        vim.list.unique(vim.list_extend(languages, vim.iter(languages):map(util.get_requires):flatten():totable()))
    end
    -- don't wait for languages already timed out
    languages = vim.iter(languages):filter(util.notin(M.timeout)):totable()
    timeout = timeout or 60000
    M.lua([[
    success, reason = vim.wait(
        ]] .. timeout .. [[,
        function()
            return not vim.iter(]] .. vim.inspect(languages) .. [[):any(util.getter(installer.installing))
        end
    )]])

    local err
    if not M.lua_get("success") then
        local reason = M.lua_get("reason")
        local failed =
            M.lua_get("vim.iter(" .. vim.inspect(languages) .. "):filter(util.getter(installer.installing)):totable()")
        if reason == -1 then
            vim.list_extend(M.timeout, failed)
        end
        err = (reason == -1) and "timeout " or (reason == -2) and "interrupt " or ""
        err = err .. "installing " .. table.concat(failed, " ")
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

---@param languages string[]
---@param timeout? number default 60,000 ms
---@param return_error? boolean whether to return or throw an error (default false)
function M.install(languages, timeout, return_error)
    M.lua("installer.install(" .. vim.inspect(languages) .. ")")
    return M.wait_installed(languages, timeout, return_error)
end

---@param languages string[]
---@param timeout? number default 10,000 ms
---@param return_error? boolean whether to return or throw an error (default false)
function M.wait_removed(languages, timeout, return_error)
    languages = type(languages) == "string" and { languages } or { unpack(languages) }
    timeout = timeout or 10000
    M.lua([[
    installed = {}
    success, reason = vim.wait(
        ]] .. timeout .. [[,
        function()
            for _, lang in ipairs(]] .. vim.inspect(languages) .. [[) do
                installed[lang] = (installed[lang] == nil or installed[lang]) and util.is_installed(lang)
            end
            return not vim.iter(installed):any(function(_, val) return val end)
        end
    )]])

    local err
    local failed = M.lua_get("vim.iter(" .. vim.inspect(languages) .. "):filter(util.getter(installed)):totable()")
    if #failed > 0 then
        local reason = M.lua_get("reason")
        err = (reason == -1) and "timeout " or (reason == -2) and "interrupt " or ""
        err = err .. "removing " .. table.concat(failed, " ")
    end

    if return_error then
        return err
    elseif err then
        error("\n" .. err)
    end
end

---@param languages string[]
---@param timeout? number default 10,000 ms
---@param return_error? boolean whether to return or throw an error (default false)
function M.remove(languages, timeout, return_error)
    M.lua("installer.remove(" .. vim.inspect(languages) .. ")")
    return M.wait_removed(languages, timeout, return_error)
end

---@param languages string[]
---@param query "parser" | "aerial" | "folds" | "highlights" | "indents" | "injections" | "locals" | "tags"
function M.works(languages, query)
    languages = type(languages) == "string" and { languages } or languages
    local condition = query ~= "parser" and "vim.treesitter.query.get(lang, '" .. query .. "')"
        or "pcall(vim.treesitter.get_string_parser, '', lang)"
    local works = M.lua_get(
        "vim.iter(" .. vim.inspect(languages) .. "):filter(function(lang) return " .. condition .. " end):totable()"
    )
    eq(languages, works)
end

---@param languages string[]
---@param query "parser" | "aerial" | "folds" | "highlights" | "indents" | "injections" | "locals" | "tags"
function M.fails(languages, query)
    languages = type(languages) == "string" and { languages } or languages
    local condition = query ~= "parser" and "vim.treesitter.query.get(lang, '" .. query .. "')"
        or "pcall(vim.treesitter.get_string_parser, '', lang)"
    local fails = M.lua_get(
        "vim.iter(" .. vim.inspect(languages) .. "):filter(function(lang) return not " .. condition .. " end):totable()"
    )
    eq(languages, fails)
end

return M
