local src = debug.getinfo(1, "S").source
local abs = src:sub(1, 1) == "@" and vim.fn.fnamemodify(src:sub(2), ":p") or ""

local config = require("tree-sitter-manager.config")
local invalid = require("tree-sitter-manager.invalid-filetypes")

local M = {}

M.PLUGIN_ROOT = abs ~= "" and vim.fn.fnamemodify(abs, ":h:h:h") or vim.fn.stdpath("config")

---concat({1,2,3}, {4,5}) = {1,2,3,4,5}
---Does not mutate lists.
---@vararg any[]
---@return any[]
function M.concat(...)
    return vim.iter({ ... }):flatten():totable()
end

---get(key)(tbl) = tbl[key]
---@return function
function M.get(key)
    return function(tbl)
        return tbl[key]
    end
end

---getter(tbl)(key) = tbl[key]
---@return function
function M.getter(tbl)
    return function(key)
        return tbl[key]
    end
end

---isin({ x, y, z })(x) = true
---@return function
function M.isin(list)
    return function(val)
        return vim.list_contains(list, val)
    end
end

---notin({ x, y, z })(w) = true
---@return function
function M.notin(list)
    return function(val)
        return not vim.list_contains(list, val)
    end
end

---@return string parser extension
function M.ext()
    local sys = vim.uv.os_uname().sysname
    return sys:match("Windows") and ".dll" or sys:match("Darwin") and ".dylib" or ".so"
end

---@return string parser path
function M.ppath(lang)
    return vim.fs.joinpath(config.cfg.parser_dir, lang .. M.ext())
end

---@return string query path
function M.qpath(lang)
    return vim.fs.joinpath(config.cfg.query_dir, lang)
end

---Wrapper for vim.treesitter.language.get_filetypes()
---@return string[] list of filetypes
function M.get_filetypes(lang)
    return vim.iter(vim.treesitter.language.get_filetypes(lang)):filter(M.notin(invalid)):totable()
end

---@return string[] Flat dependency tree.
function M.get_requires(lang)
    local entry = config.effective_repos[lang]
    local deps = entry and entry.requires or {}

    for _, lang in ipairs(deps) do
        entry = config.effective_repos[lang]
        local _deps = entry and entry.requires or {}
        vim.list.unique(vim.list_extend(deps, _deps))
    end

    return deps
end

---@return table | nil
function M.get_repo_info(lang)
    local entry = config.effective_repos[lang]
    if not entry then
        return nil
    end
    if type(entry) == "string" then
        return { url = entry }
    end
    if entry.install_info then
        return {
            url = entry.install_info.url,
            location = entry.install_info.location,
            revision = entry.install_info.revision,
            branch = entry.install_info.branch,
            generate = entry.install_info.generate,
            queries = entry.install_info.queries,
        }
    end
    return nil
end

function M.is_only_query(lang)
    local info = M.get_repo_info(lang)
    return not info or not info.url
end

function M.not_only_query(lang)
    return not M.is_only_query(lang)
end

function M.is_installed(lang)
    if vim.list_contains(config.cfg.assume_installed, lang) then
        return true
    elseif M.is_only_query(lang) then
        return nil ~= vim.uv.fs_stat(M.qpath(lang))
    else
        return nil ~= vim.uv.fs_stat(M.ppath(lang))
    end
end

function M.not_installed(lang)
    return not M.is_installed(lang)
end

---@class Status
---@field ok? boolean
---@field error? string
---@field output? string

---@class AsyncJob
---@field wait fun(self: AsyncJob, timeout?: number): Status
---@field start fun(self: AsyncJob) Start the job immediately.
---@field active boolean

---@class Queue: AsyncJob[]
---@field new fun(self): Queue
---@field find fun(self, job: AsyncJob): number, AsyncJob
---@field add fun(self, job: AsyncJob)
---@field remove fun(self, job: AsyncJob)
---@field start_next_batch fun(self) Start the next batch capped at `async_size`
local Queue = {}
Queue.__index = Queue

function Queue:new()
    return setmetatable({}, self)
end

---@return number The index of the job
---@return AsyncJob The job itself
function Queue:find(job)
    return vim.iter(ipairs(self)):find(function(_, j)
        return j == job
    end)
end

Queue.add = table.insert

function Queue:remove(job)
    local i = self:find(job) or 0
    table.remove(self, i)
end

function Queue:start_next_batch()
    local active = #vim.iter(self):filter(M.get("active")):totable()
    for i = active + 1, math.min(#self, vim.env.ASYNC_SIZE or config.cfg.async_size) do
        self[i]:start()
    end
end

M.Queue = Queue
M.global_queue = Queue:new()

---@class runOptions : vim.SystemOpts
---@field callback? fun(out: Status) If not given the job skips the queue.
---@field status? Status If not status.ok, the job is skipped to the callback.
---@field queue? Queue Jobs are queued, by default `global_queue`. Use Queue:new() to skip the queue.

---@param args string[]
---@param opts? runOptions
---@return AsyncJob?
function M.run(args, opts)
    opts = opts or {}
    local status = opts.status or { ok = true }
    local queue = opts.queue or opts.callback and Queue:new() or M.global_queue
    local callback = opts.callback or function() end

    if not status.ok then
        callback(status)
        return
    end

    local job = {}
    ---@cast job AsyncJob

    function job:start()
        self.start = function() end -- subsequent calls do nothing

        opts.text = true
        local obj = vim.system(args, opts, function(out)
            vim.schedule(function()
                queue:remove(self)
                queue:start_next_batch()
                local err = table.concat(args, " ") .. "\n" .. (out.stderr or "")
                callback({ ok = out.code == 0, error = err, output = out.stdout })
            end)
        end)

        function self:wait(...) -- replace job:wait with the actual SystemObj:wait
            local out = obj:wait(...)
            local err = table.concat(args, " ") .. "\n" .. (out.stderr or "")
            return { ok = out.code == 0, error = err, output = out.stdout }
        end

        self.active = true
    end

    function job:wait(timeout)
        timeout = timeout or math.huge
        local start = vim.uv.hrtime()
        -- wait until the job starts
        if vim.wait(timeout, function()
            return self.active
        end) then -- wait until the job finishes
            return self:wait(timeout - (vim.uv.hrtime() - start) / 1e6)
        else
            return { ok = false, error = "Timeout before job started." }
        end
    end

    queue:add(job)
    queue:start_next_batch()

    return job
end

function M.copy_dir(src, dst)
    local ok, err = pcall(vim.fn.mkdir, dst, "p")

    if ok then
        for name, ftype in vim.fs.dir(src) do
            local s = vim.fs.joinpath(src, name)
            local d = vim.fs.joinpath(dst, name)
            if ftype == "directory" then
                local res = M.copy_dir(s, d)
                ok, err = res.ok, res.error
            else
                ok, err = vim.uv.fs_copyfile(s, d)
            end
            if not ok then
                break
            end
        end
    end

    if ok then
        return { ok = true }
    else
        return { ok = false, error = "copy_dir(" .. src .. ", " .. dst .. ")\n" .. err }
    end
end

return M
