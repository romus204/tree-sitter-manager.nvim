local M = {}
local repos = require("tree-sitter-manager.repos")

local src = debug.getinfo(1, "S").source
local abs = src:sub(1, 1) == "@" and vim.fn.fnamemodify(src:sub(2), ":p") or ""
local PLUGIN_ROOT = abs ~= "" and vim.fn.fnamemodify(abs, ":h:h:h") or vim.fn.stdpath("config")

local footer = " [i] Install  [x] Remove  [u] Update  [r] Refresh  [q] Close "

local cfg = {
    parser_dir = vim.fn.stdpath("data") .. "/site/parser",
    query_dir = vim.fn.stdpath("data") .. "/site/queries",
    ---@type table<string, string|{install_info?: {url: string, location?: string, revision?: string, branch?: string, generate?: boolean, use_repo_queries?: boolean}, requires?: string[]}>
    languages = {},
    ensure_installed = {},

}

-- Effective repos: built-in repos merged with user-defined overrides from cfg.languages.
-- Recomputed in setup() after merging user config.
local effective_repos = repos
local languages = vim.tbl_keys(repos)
table.sort(languages)

local function ext()
    local sys = vim.uv.os_uname().sysname
    return sys:match("Windows") and ".dll" or sys:match("Darwin") and ".dylib" or ".so"
end

local function ppath(l) return cfg.parser_dir .. "/" .. l .. ext() end
local function qpath(l) return cfg.query_dir .. "/" .. l end

-- Runs a command given as an argument array, optionally in a working directory.
-- Avoids shell invocation so this works on Windows, macOS, and Linux.
local function run_cmd(args, cwd)
    local opts = { text = true }
    if cwd then opts.cwd = cwd end
    local res = vim.system(args, opts):wait()
    local out = (res.stderr ~= "" and res.stderr) or res.stdout or ""
    return { ok = res.code == 0, output = out }
end

-- Recursively copies all files from src directory into dst directory.
local function copy_dir(src, dst)
    vim.fn.mkdir(dst, "p")
    local handle = vim.uv.fs_scandir(src)
    if not handle then return end
    while true do
        local name, ftype = vim.uv.fs_scandir_next(handle)
        if not name then break end
        local s = src .. "/" .. name
        local d = dst .. "/" .. name
        if ftype == "directory" then
            copy_dir(s, d)
        else
            vim.uv.fs_copyfile(s, d)
        end
    end
end

local function get_repo_info(lang)
    local entry = effective_repos[lang]
    if not entry then return nil end
    if type(entry) == "string" then return { url = entry, location = lang } end
    if entry.install_info then
        return {
            url = entry.install_info.url,
            location = entry.install_info.location or lang,
            revision = entry.install_info.revision,
            branch = entry.install_info.branch,
            generate = entry.install_info.generate,
            use_repo_queries = entry.install_info.use_repo_queries,
        }
    end
    return nil
end

local function get_requires(lang)
    local entry = effective_repos[lang]
    return (type(entry) == "table" and entry.requires) or {}
end

local function install_with_deps(lang, installing)
    installing = installing or {}
    if installing[lang] then
        vim.notify("⚠ Circular dependency: " .. lang, vim.log.levels.WARN)
        return false
    end
    installing[lang] = true

    for _, dep in ipairs(get_requires(lang)) do
        if not vim.uv.fs_stat(ppath(dep)) then
            vim.notify("📦 Installing dependency: " .. dep, vim.log.levels.INFO)
            if not install_with_deps(dep, vim.deepcopy(installing)) then return false end
        end
    end
    return M._install_single(lang)
end

local function copy_queries(lang, location)
    local s = PLUGIN_ROOT .. "/runtime/queries/" .. location
    local d = cfg.query_dir .. "/" .. lang
    if vim.uv.fs_stat(s) then
        copy_dir(s, d)
    end
end

-- Copies query files from the cloned grammar repository into query_dir.
-- Expects queries at <build_dir>/queries/ (standard tree-sitter layout).
local function copy_queries_from_repo(lang, build_dir)
    local qs = build_dir .. "/queries"
    if vim.uv.fs_stat(qs) then
        copy_dir(qs, cfg.query_dir .. "/" .. lang)
        return true
    end
    return false
end

function M._install_single(lang)
    local info = get_repo_info(lang)
    if not info or not info.url then
        copy_queries(lang, lang) -- if only queries require
        vim.notify("✓ " .. lang .. " installed")
        return true
    end

    local tmp = vim.fn.tempname()
    local location = info.location or lang

    vim.notify("⬇ Cloning " .. lang)
    local clone = run_cmd({ "git", "clone", info.url, tmp })
    if not clone.ok then
        return vim.notify("Clone failed:\n" .. clone.output:sub(1, 300), 3), false
    end

    local ref = info.revision or info.branch
    if ref then
        vim.notify("🔖 Checkout " .. ref)
        local checkout = run_cmd({ "git", "checkout", ref }, tmp)
        if not checkout.ok then
            vim.notify("⚠ Checkout failed:\n" .. checkout.output:sub(1, 200), 2)
        end
    end

    local build_dir = tmp
    if info.location then
        vim.notify("LOCATION " .. location)
        build_dir = tmp .. "/" .. location
    end

    vim.notify("🔨 Building " .. lang)
    local build = {}
    if info.generate then
        local gen = run_cmd({ "tree-sitter", "generate" }, build_dir)
        if not gen.ok then
            vim.notify("Generate failed for " .. lang .. ":\n" .. gen.output:sub(1, 300), 3)
            vim.fn.delete(tmp, "rf")
            return false
        end
    end
    build = run_cmd({ "tree-sitter", "build", "-o", ppath(lang) }, build_dir)

    if not build.ok then
        local err = build.output
        if #err > 500 then err = err:sub(-500) end
        vim.notify("Build failed for " .. lang .. ":\n" .. err, 3)
        vim.fn.delete(tmp, "rf")
        return false
    end

    -- Copy queries from the cloned repo when use_repo_queries is set.
    -- Must happen before tmp is deleted.
    local used_repo_queries = false
    if info.use_repo_queries then
        used_repo_queries = copy_queries_from_repo(lang, build_dir)
        if not used_repo_queries then
            vim.notify("⚠ No queries/ found in repo for " .. lang .. ", falling back to bundled queries", 2)
        end
    end

    vim.fn.delete(tmp, "rf")

    if not used_repo_queries then
        copy_queries(lang, location)
    end

    vim.notify("✓ " .. lang .. " installed")
    return true
end

local function install(lang) install_with_deps(lang) end

local function remove(lang)
    if vim.uv.fs_stat(ppath(lang)) then vim.uv.fs_unlink(ppath(lang)) end
    local qd = cfg.query_dir .. "/" .. lang
    if vim.uv.fs_stat(qd) then vim.fn.delete(qd, "rf") end
    vim.notify("✕ " .. lang)
end

local function is_only_query(lang)
    local info = get_repo_info(lang)
    return not info or not info.url
end

--TODO: DO REFACTOR
local function get_status_icon(lang)
    if is_only_query(lang) then
        if not vim.uv.fs_stat(qpath(lang)) then return "❌" end
    else
        if not vim.uv.fs_stat(ppath(lang)) then return "❌" end
    end

    for _, dep in ipairs(get_requires(lang)) do
        if is_only_query(dep) then
            if not vim.uv.fs_stat(qpath(dep)) then return "⚠️" end
        else
            if not vim.uv.fs_stat(ppath(dep)) then return "⚠️" end
        end
    end

    return "✅"
end

local function get_meta_suffix(lang)
    local info = get_repo_info(lang)
    local parts = {}
    if info and info.revision then table.insert(parts, string.sub(info.revision, 1, 7)) end
    local reqs = get_requires(lang)
    if #reqs > 0 then table.insert(parts, "requires:" .. table.concat(reqs, ",")) end
    return #parts > 0 and "  " .. table.concat(parts, " ") or ""
end

local function render(buf)
    local lines = { " 🌳  Tree-sitter Parser Manager ", " ────────────────────────────────" }
    for _, l in ipairs(languages) do
        table.insert(lines, string.format("   %-12s  %s%s", l, get_status_icon(l), get_meta_suffix(l)))
    end

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
end

function M.setup(opts)
    cfg = vim.tbl_deep_extend("force", cfg, opts or {})

    -- Merge built-in repos with user-defined language overrides.
    -- User entries take precedence, allowing custom forks and new languages.
    effective_repos = vim.tbl_deep_extend("force", vim.deepcopy(repos), cfg.languages)
    languages = vim.tbl_keys(effective_repos)
    table.sort(languages)

    vim.fn.mkdir(cfg.parser_dir, "p")
    vim.fn.mkdir(cfg.query_dir, "p")

    local parser_parent = vim.fn.fnamemodify(cfg.parser_dir, ":h")
    local query_parent = vim.fn.fnamemodify(cfg.query_dir, ":h")
    local rtp = vim.opt.rtp:get()

    if not vim.tbl_contains(rtp, parser_parent) then vim.opt.rtp:prepend(parser_parent) end
    if not vim.tbl_contains(rtp, query_parent) then vim.opt.rtp:prepend(query_parent) end

    for _, lang in ipairs(cfg.ensure_installed or {}) do
        if not repos[lang] then
            vim.notify("⚠ Parser not found in repos: " .. lang, vim.log.levels.WARN)
        else
            local installed = false
            if is_only_query(lang) then
                installed = vim.uv.fs_stat(qpath(lang)) ~= nil
            else
                installed = vim.uv.fs_stat(ppath(lang)) ~= nil
            end
            if not installed then install(lang) end
        end
    end

    vim.api.nvim_create_user_command("TSManager", function() M.open() end,
        { nargs = 0, desc = "Open Tree-sitter Parsers Manager" })

    local installed_ft = {}
    for _, lang in ipairs(languages) do
        if vim.uv.fs_stat(ppath(lang)) then table.insert(installed_ft, lang) end
    end
    if #installed_ft > 0 then
        vim.api.nvim_create_autocmd("FileType", {
            pattern = installed_ft,
            callback = function() vim.treesitter.start() end,
            desc = "Auto-enable treesitter for installed parsers",
        })
    end
end

function M.open()
    local max_w = #footer
    for _, l in ipairs(languages) do max_w = math.max(max_w, #("   " .. l .. "  ✅  abc1234  requires:x,y")) end
    local w = math.max(max_w + 4, 40)
    local h = math.min(#languages + 6, vim.o.lines - 15)

    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = w,
        height = h,
        style = "minimal",
        border = "rounded",
        row = math.floor((vim.o.lines - h) / 2),
        col = math.floor((vim.o.columns - w) / 2),
        title = footer,
        title_pos = "center",
    })
    render(buf)

    local close_fn = function() vim.api.nvim_win_close(win, true) end
    vim.keymap.set("n", "q", close_fn, { buffer = buf, noremap = true, silent = true })
    vim.keymap.set("n", "<Esc>", close_fn, { buffer = buf, noremap = true, silent = true })
    vim.keymap.set("n", "r", function() render(buf) end, { buffer = buf, noremap = true, silent = true })
    vim.keymap.set("n", "i", function() M._act("install") end, { buffer = buf, noremap = true, silent = true })
    vim.keymap.set("n", "x", function() M._act("remove") end, { buffer = buf, noremap = true, silent = true })
    vim.keymap.set("n", "u", function() M._act("update") end, { buffer = buf, noremap = true, silent = true })
end

function M._act(action)
    local lang = vim.api.nvim_get_current_line():match("^%s*([%w_]+)")
    if not lang or not effective_repos[lang] then return end
    if action == "install" then
        install(lang)
    elseif action == "remove" then
        remove(lang)
    elseif action == "update" then
        remove(lang)
        install(lang)
    end
    render(vim.api.nvim_get_current_buf())
end

return M
