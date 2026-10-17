local M = {}

---@return string
local function lock_path()
    return vim.fn.stdpath("state") .. "/tsm-lock.json"
end

--- @return table
function M.lock_read()
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
function M.lock_set(lang, sha)
    local data = M.lock_read()
    data[lang] = sha
    M.lock_write(data)
end

---@param lang string
function M.lock_remove(lang)
    local data = M.lock_read()
    data[lang] = nil
    M.lock_write(data)
end

---@param langs string[]
function M.lock_remove_langs(langs)
    local data = M.lock_read()
    for _, lang in ipairs(langs) do
        data[lang] = nil
    end
    M.lock_write(data)
end

---@param lang string
---@return string|nil
function M.lock_get(lang)
    return M.lock_read()[lang]
end

return M
