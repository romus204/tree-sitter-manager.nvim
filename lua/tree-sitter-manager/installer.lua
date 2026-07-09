local config = require("tree-sitter-manager.config")
local util = require("tree-sitter-manager.util")
local backport = require("tree-sitter-manager.backport")

local notify_nerd = { "✕ ", "📦 ", "󰚰 ", "⚠ ", "✓ ", "⚙️ ", "🔨 " }
local notify_icon

---@class Installer
---@field installing table<Lang, boolean>
---@field status     table<Lang, Status>
---@field remove  fun(lang:Lang|Lang[], callback:fun(out:Status)) Remove languages and run callback.
---@field install fun(lang:Lang|Lang[], callback:fun(out:Status)) Install languages and run callback on every language.
---@field update  fun(lang:Lang|Lang[], callback:fun(out:Status)) Update languages and run callback on every language.
---
---@alias Lang string
local M = { installing = {}, status = {} }

function M.setup()
    notify_icon = config.cfg.nerdfont and notify_nerd or vim.fn["repeat"]({ "" }, 7)
end

local function copy_queries(lang, source)
    local qpath = util.qpath(lang)
    if not source then
        source = vim.fs.joinpath(util.PLUGIN_ROOT, "runtime/queries", lang)
        vim.fs.rm(qpath, { recursive = true, force = true })
        ok, err = vim.uv.fs_symlink(source, qpath, { dir = true })
        return { ok = ok, error = err and lang .. ": copy_queries\n" .. err }
    elseif vim.uv.fs_stat(source) then
        return util.copy_dir(source, qpath)
    else
        return { ok = false, error = lang .. ": invalid queries: " .. source }
    end
end

local function build(lang, info, tmpdir, status, callback)
    local build_path = vim.fs.joinpath(tmpdir, info.location)
    if status.ok and not vim.uv.fs_stat(build_path) then
        status = { ok = false, error = lang .. ": invalid location: " .. info.location }
    end

    local _status = { ok = status.ok and info.generate, error = status.error }
    if _status.ok then
        vim.notify(notify_icon[6] .. "Generating " .. lang)
    end

    local queue = util.Queue:new() -- skip global_queue
    util.run({ "tree-sitter", "generate" }, {
        cwd = build_path,
        status = _status,
        queue = queue,
        callback = function(out)
            out = info.generate and out or status
            if out.ok then
                vim.notify(notify_icon[7] .. "Building " .. lang)
            end
            util.run({ "tree-sitter", "build", "-o", util.ppath(lang) }, {
                cwd = build_path,
                status = out,
                queue = queue,
                callback = function(out)
                    if out.ok then
                        out = copy_queries(lang, info.queries and vim.fs.joinpath(build_path, info.queries))
                    end
                    vim.fs.rm(tmpdir, { recursive = true, force = true })
                    callback(out)
                end,
            })
        end,
    })
end

local function install(lang, callback)
    callback = callback or function() end

    if util.is_only_query(lang) then
        callback(copy_queries(lang))
        return
    end

    local out = util.run({ "git", "version" }):wait()
    if not out.ok then
        callback(out)
        return
    end
    local version = { out.output:match("(%d+)%.(%d+)%.(%d+)") }
    local major, minor, patch = unpack(vim.iter(version):map(tonumber):totable())

    local info = util.get_repo_info(lang)
    local tmpdir = vim.fn.tempname()
    local git_args = { "git", "--work-tree=" .. tmpdir, "--git-dir=" .. tmpdir .. "/.git" }

    local has_revision = major > 2 or major == 2 and minor >= 49

    if info.revision and not has_revision then
        -- Git pre 2.49.0 doesn't have --revision flag
        out = util.run(util.concat(git_args, { "init", tmpdir })):wait()
        if out.ok then
            out = util.run(util.concat(git_args, { "remote", "add", "origin", info.url })):wait()
        end
        util.run(util.concat(git_args, { "fetch", "--depth=1", "origin", info.revision }), {
            status = out,
            callback = function(out)
                if out.ok then
                    out = util.run(util.concat(git_args, { "checkout", "FETCH_HEAD" })):wait()
                end
                build(lang, info, tmpdir, out, callback)
            end,
        })
    else
        local revision = info.revision and "--revision=" .. info.revision
        local branch = info.branch and "--branch=" .. info.branch
        util.run(util.concat(git_args, { "clone", "--depth=1", info.url, tmpdir, revision or branch }), {
            status = out,
            callback = function(out)
                build(lang, info, tmpdir, out, callback)
            end,
        })
    end
end

function M.remove(languages, callback, update)
    languages = type(languages) == "string" and { languages } or languages
    callback = callback or function() end

    local uninstalled = {}
    for _, lang in ipairs(languages) do
        if util.is_installed(lang) then
            vim.fs.rm(util.ppath(lang), { recursive = true, force = true })
            vim.fs.rm(util.qpath(lang), { recursive = true, force = true })
            M.status[lang] = nil
            table.insert(uninstalled, lang)
        end
    end

    if not update and #uninstalled > 0 then
        vim.notify(notify_icon[1] .. "Removed " .. table.concat(uninstalled, " "))
        callback({ ok = true })
    end
end

function M.install(languages, callback, update)
    languages = type(languages) == "string" and { languages } or languages

    local lang_n_deps = {}
    for i, lang in ipairs(languages) do
        table.insert(lang_n_deps, lang)
        if not vim.list_contains(config.cfg.assume_installed, lang) then
            vim.list_extend(lang_n_deps, util.get_requires(lang))
        end
    end
    languages = vim.list.unique(lang_n_deps)

    local installing = {}
    for _, lang in ipairs(languages) do
        if not config.effective_repos[lang] then
            M.status[lang] = { ok = false, error = lang .. ": not in repos" }
            vim.notify(notify_icon[4] .. lang .. " not in repos", vim.log.levels.WARN)
        elseif util.is_installed(lang) then
            M.status[lang] = { ok = true }
        elseif M.installing[lang] then
        else
            install(lang, function(out)
                M.status[lang] = out
                M.installing[lang] = nil
                if not out.ok then
                    vim.notify(notify_icon[4] .. "Error installing " .. lang .. "\n" .. out.error, vim.log.levels.WARN)
                else
                    vim.notify(notify_icon[5] .. (update and "Updated " or "Installed ") .. lang)
                    -- refresh queries and update highlighting
                    vim.treesitter.query.get:clear()
                    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                        pcall(vim.treesitter.start, buf)
                    end
                end
                if callback then
                    callback(out)
                end
            end)
            if util.not_only_query(lang) then
                M.installing[lang] = true
                table.insert(installing, lang)
            end
        end
    end

    if #installing > 0 then
        if update then
            vim.notify(notify_icon[3] .. "Updating " .. table.concat(installing, " "))
        else
            vim.notify(notify_icon[2] .. "Installing " .. table.concat(installing, " "))
        end
    end
end

function M.update(languages, callback)
    M.remove(languages, callback, true)
    M.install(languages, callback, true)
end

-- Backward compatibility
backport._install_single = install

return M
