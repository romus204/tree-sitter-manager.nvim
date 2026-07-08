local languages = _G.languages or { "tsv", "typescript", "glimmer_typescript" }

local T = new_set()

T.open = function()
    child.cmd("TSManager")
end

T.install = function()
    child.cmd("g/\\v^ *(" .. table.concat(languages, "|") .. ") /normal i")
    child.wait_installed(languages)
end

T.update = function()
    child.wait_installed(languages)
    child.cmd("g/\\v^ *(" .. table.concat(languages, "|") .. ") /normal u")
    child.wait_installed(languages)
end

local installed, deps
T.filter = MiniTest.new_set()
T.filter.installed = function()
    child.cmd("normal f")
    local lines = child.lua_get("vim.api.nvim_buf_get_lines(0, 0, -1, false)")
    installed = vim.iter(lines)
        :map(function(line)
            return line:match("%S+")
        end)
        :totable()
    eq({}, vim.iter(languages):filter(util.notin(installed)):totable())
end
T.filter.warning = function()
    deps = vim.iter(installed):filter(util.notin(languages)):totable()
    if #deps == 0 then
        MiniTest.skip("no dependencies")
    end
    child.remove(deps)
    child.cmd("normal f")
    local warns = child.lua_get("vim.api.nvim_buf_get_lines(0, 0, -1, false)")
    neq({}, warns)
end
T.filter.missing = function()
    if vim.deep_equal(languages, config.languages) then
        MiniTest.skip("installed all")
    end
    child.cmd("normal f")
    local lines = child.lua_get("vim.api.nvim_buf_get_lines(0, 0, -1, false)")
    local missing = vim.iter(lines)
        :map(function(line)
            return line:match("%S+")
        end)
        :totable()
    eq({}, vim.iter(languages):filter(util.isin(missing)):totable())
end
T.filter.all = function()
    child.cmd("normal f")
end

T.remove = function()
    child.wait_installed(languages)
    child.cmd("g/\\v^ *(" .. table.concat(languages, "|") .. ") /normal x")
    child.wait_removed(languages)
end

return T
