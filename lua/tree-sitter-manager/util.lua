local src = debug.getinfo(1, "S").source
local abs = src:sub(1, 1) == "@" and vim.fn.fnamemodify(src:sub(2), ":p") or ""

local config = require("tree-sitter-manager.config")

local M = {}

M.PLUGIN_ROOT = abs ~= "" and vim.fn.fnamemodify(abs, ":h:h:h") or vim.fn.stdpath("config")

function M.ext()
    local sys = vim.uv.os_uname().sysname
    return sys:match("Windows") and ".dll" or sys:match("Darwin") and ".dylib" or ".so"
end

function M.ppath(l) return config.cfg.parser_dir .. "/" .. l .. M.ext() end
function M.qpath(l) return config.cfg.query_dir .. "/" .. l end

function M.run_cmd(args, cwd, callback)
    local opts = { text = true }
    if cwd then opts.cwd = cwd end
    vim.system(args, opts, function(res)
        local out = (res.stderr ~= "" and res.stderr) or res.stdout or ""
        vim.schedule(function()
            callback({ ok = res.code == 0, output = out })
        end)
    end)
end

function M.copy_dir(src, dst)
    vim.fn.mkdir(dst, "p")
    local handle = vim.uv.fs_scandir(src)
    if not handle then return end
    while true do
        local name, ftype = vim.uv.fs_scandir_next(handle)
        if not name then break end
        local s = src .. "/" .. name
        local d = dst .. "/" .. name
        if ftype == "directory" then
            M.copy_dir(s, d)
        else
            vim.uv.fs_copyfile(s, d)
        end
    end
end

local function lock_path()
    return config.cfg.parser_dir .. "/lock.json"
end

function M.lock_read()
    local path = lock_path()
    local fd = io.open(path, "r")
    if not fd then return {} end
    local content = fd:read("*a")
    fd:close()
    local ok, data = pcall(vim.json.decode, content)
    return (ok and type(data) == "table") and data or {}
end

function M.lock_write(data)
    local path = lock_path()
    local fd = io.open(path, "w")
    if not fd then return end
    fd:write(vim.json.encode(data))
    fd:close()
end

function M.lock_set(lang, entry)
    local data = M.lock_read()
    data[lang] = entry
    M.lock_write(data)
end

function M.lock_remove(lang)
    local data = M.lock_read()
    data[lang] = nil
    M.lock_write(data)
end

function M.lock_get(lang)
    return M.lock_read()[lang]
end

return M
