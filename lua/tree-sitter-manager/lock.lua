local M = {}

---data is just used to make unit test
---when used, it will always read the file and get the content again
---@type table<string, string>
M.data = {}

---@return string
local function lock_path()
    return vim.fn.stdpath("state") .. "/tsm-lock.json"
end

--- @return table
---@param dry? boolean
function M.lock_data(dry)
    if dry then
        return M.data
    end
    local path = lock_path()
    local fd = io.open(path, "r")
    if not fd then
        return {}
    end
    local content = fd:read("*a")
    if type(content) ~= "string" then
        return {}
    end
    fd:close()
    local ok, data = pcall(vim.json.decode, content)
    return (ok and type(data) == "table") and data or {}
end

--- @param data table
function M.lock_write(data)
    local path = lock_path()
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
    local fd = io.open(path, "w")
    if not fd then
        return
    end
    fd:write(M.json_pretty(data))
    fd:close()
end

--- @param data table
--- @param indent? string
--- @return string
function M.json_pretty(data, indent)
    indent = indent or ""
    local next_indent = indent .. "  "
    if type(data) ~= "table" then
        return vim.json.encode(data)
    end
    local keys = vim.tbl_keys(data)
    table.sort(keys)
    if #keys == 0 then
        return "{}"
    end
    local parts = {}
    for _, k in ipairs(keys) do
        table.insert(parts, next_indent .. vim.json.encode(k) .. ": " .. M.json_pretty(data[k], next_indent))
    end
    return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
end

---@param lang string
---@param sha string
---@param dry? boolean
function M.lock_set(lang, sha, dry)
    local data = M.lock_data(dry)
    data[lang] = sha
    if not dry then
        M.lock_write(data)
    end
end

---@param lang string
---@param dry? boolean
function M.lock_remove(lang, dry)
    local data = M.lock_data()
    data[lang] = nil
    if not dry then
        M.lock_write(data)
    end
end

---@param langs string[]
---@param dry? boolean
function M.lock_remove_langs(langs, dry)
    local data = M.lock_data()
    for _, lang in ipairs(langs) do
        data[lang] = nil
    end

    if not dry then
        M.lock_write(data)
    end
end

---@param lang string
---@param dry? boolean
---@return string|nil
function M.lock_get(lang, dry)
    return M.lock_data(dry)[lang]
end

return M
