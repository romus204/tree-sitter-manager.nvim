local config = require("tree-sitter-manager.config")
local util = require("tree-sitter-manager.util")

local M = { status = {} }

local function copy_queries(lang, source)
    local bundled = vim.fs.joinpath(util.PLUGIN_ROOT, "runtime/queries", lang)
    source = source or bundled
    if source then
        if not vim.uv.fs_stat(source) then
            return { ok = false, error = "copy_queries(" .. lang .. ")\n" .. source .. "not found" }
        end
    end
    return util.copy_dir(source, util.qpath(lang))
end

local function treesitter_build(lang, query_dir, build_path, generate, tmpdir, status, callback)
    _status = { ok = status.ok and generate, error = status.error }
    if _status.ok then
        vim.notify("⚙️ Generating " .. lang)
    end
    util.run_async({ "tree-sitter", "generate" }, build_path, _status, function(out)
        if not generate then
            out = status
        end
        if out.ok then
            vim.notify("🔨 Building " .. lang)
        end
        util.run_async({ "tree-sitter", "build", "-o", util.ppath(lang) }, build_path, out, function(out)
            if out.ok then
                out = copy_queries(lang, query_dir and vim.fs.joinpath(build_path, query_dir))
            end
            vim.fs.rm(tmpdir, { recursive = true, force = true })
            callback(out)
        end)
    end)
end

local function install(lang, callback)
    if util.is_only_query(lang) then
        callback(copy_queries(lang))
        return
    end

    local out = util.run({ "git", "version" })
    if not out.ok then
        callback({ ok = false, error = "Git not installed" })
        return
    end
    version = { out.output:match("(%d+)%.(%d+)%.(%d+)") }
    local major = tonumber(version[1])
    local minor = tonumber(version[2])
    local patch = tonumber(version[3])

    local info = util.get_repo_info(lang)
    local tmpdir = vim.fn.tempname()
    local build_path = vim.fs.joinpath(tmpdir, info.location)

    if info.revision and (major < 2 or major == 2 and minor < 49) then
        -- Git pre 2.49.0 doesn't have --revision flag
        out = util.run({ "git", "init", tmpdir })
        if out.ok then
            out = util.run({ "git", "remote", "add", "origin", info.url }, tmpdir)
        end
        util.run_async({ "git", "fetch", "--depth=1", "origin", info.revision }, tmpdir, out, function(out)
            if out.ok then
                out = util.run({ "git", "checkout", "FETCH_HEAD" }, tmpdir)
            end
            treesitter_build(
                lang,
                info.use_repo_queries and info.queries,
                build_path,
                info.generate,
                tmpdir,
                out,
                callback
            )
        end)
    else
        local revision = info.revision and "--revision=" .. info.revision
        local branch = info.branch and "--branch=" .. info.branch
        util.run_async(
            { "git", "--no-advice", "clone", "--depth=1", info.url, tmpdir, revision or branch },
            nil,
            out,
            function(out)
                treesitter_build(
                    lang,
                    info.use_repo_queries and info.queries,
                    build_path,
                    info.generate,
                    tmpdir,
                    out,
                    callback
                )
            end
        )
    end
end

function M.remove(languages)
    if type(languages) == "string" then
        languages = { languages }
    end
    for _, lang in ipairs(languages) do
        vim.fs.rm(util.ppath(lang), { recursive = true, force = true })
        vim.fs.rm(util.qpath(lang), { recursive = true, force = true })
        M.status[lang] = nil
    end
    vim.notify("✕ Removed: " .. table.concat(languages, " "))
end

function M.install(languages, callback, no_deps, force)
    callback = callback or function() end
    if type(languages) == "string" then
        languages = { languages }
    end
    for _, lang in ipairs(languages) do
        for _, dep in ipairs(util.get_requires(lang)) do
            if not no_deps and not vim.list_contains(languages, dep) then
                languages[#languages + 1] = dep
            end
        end
    end
    languages = vim.iter(languages)
        :filter(function(lang)
            if M.status[lang] and (M.status[lang].ok or M.status[lang].installing) then
                return false -- installed or being installed
            elseif not config.effective_repos[lang] then
                M.status[lang] = { ok = false, error = "Parser not found in repos" }
                vim.notify("⚠ Parser not found in repos: " .. lang, vim.log.levels.WARN)
                return false
            elseif not force and util.is_installed(lang) then
                M.status[lang] = { ok = true }
                return false
            else
                M.status[lang] = { installing = true }
                return true
            end
        end)
        :totable()

    if #languages > 0 then
        vim.notify("📦 Installing: " .. table.concat(languages, " "))
    end
    for _, lang in ipairs(languages) do
        install(lang, function(out)
            M.status[lang] = out
            callback(out)
            if out.ok then
                vim.notify("✓ Installed " .. lang)
            else
                vim.notify("⚠ Error installing " .. lang .. "\n" .. out.error, vim.log.levels.WARN)
            end
            if out.ok then
                -- refresh queries and update highlighting
                vim.treesitter.query.get:clear()
                for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                    pcall(vim.treesitter.start, buf)
                end
            end
        end)
    end
end

return M
