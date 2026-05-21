local src = debug.getinfo(1, "S").source
local abs = src:sub(1, 1) == "@" and vim.fn.fnamemodify(src:sub(2), ":p") or ""

local config = require("tree-sitter-manager.config")

local M = {}

M.PLUGIN_ROOT = abs ~= "" and vim.fn.fnamemodify(abs, ":h:h:h") or vim.fn.stdpath("config")

function M.ext()
    local sys = vim.uv.os_uname().sysname
    return sys:match("Windows") and ".dll" or sys:match("Darwin") and ".dylib" or ".so"
end

function M.ppath(l)
    return vim.fs.joinpath(config.cfg.parser_dir, l .. M.ext())
end
function M.qpath(l)
    return vim.fs.joinpath(config.cfg.query_dir, l)
end

function M.run(args, cwd)
    local opts = { text = true, cwd = cwd }
    local res = vim.system(args, opts):wait()
    if res.code ~= 0 then
        local args = table.concat(args, " ")
        local stderr = res.stderr or ""
        vim.notify("Failed " .. args .. "\n" .. stderr, vim.log.levels.ERROR)
    end
    return res.code == 0, res.stdout or ""
end

function M.run_async(args, callback, cwd)
    local callback = callback or function() end
    local opts = { text = true, cwd = cwd }
    vim.system(args, opts, function(res)
        vim.schedule(function()
            if res.code ~= 0 then
                local args = table.concat(args, " ")
                local stderr = res.stderr or ""
                vim.notify("Failed " .. args .. "\n" .. stderr, vim.log.levels.ERROR)
            end
            callback(res.code == 0)
        end)
    end)
end

function M.copy_dir(src, dst)
    vim.fn.mkdir(dst, "p")
    local handle = vim.uv.fs_scandir(src)
    if not handle then
        return
    end
    while true do
        local name, ftype = vim.uv.fs_scandir_next(handle)
        if not name then
            break
        end
        local s = vim.fs.joinpath(src, name)
        local d = vim.fs.joinpath(dst, name)
        if ftype == "directory" then
            M.copy_dir(s, d)
        else
            vim.uv.fs_copyfile(s, d)
        end
    end
end

return M
