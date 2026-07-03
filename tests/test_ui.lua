local languages = _G.languages or { "tsv", "typescript", "glimmer_typescript" }

local T = new_set()

T["open"] = function()
    child.cmd("TSManager")
end

T["install"] = function()
    child.cmd("g/\\v^ *(" .. table.concat(languages, "|") .. ") /normal i")
    child.wait(languages)
    child.works(languages, "parser")
end

T["update"] = function()
    child.works(languages, "parser")
    child.cmd("g/\\v^ *(" .. table.concat(languages, "|") .. ") /normal u")
    eq(
        false,
        child.lua_get(
            "vim.iter(" .. vim.inspect(languages) .. "):filter(util.no(util.is_only_query)):any(util.is_installed)"
        )
    )
    child.wait(languages)
    child.works(languages, "parser")
end

local installed, deps
T["filter"] = MiniTest.new_set()
T["filter"]["installed"] = function()
    child.cmd("normal f")
    local lines = child.lua_get("vim.api.nvim_buf_get_lines(0, 0, -1, false)")
    installed = vim.iter(lines)
        :map(function(line)
            return line:match("%S+")
        end)
        :totable()
    eq(true, vim.iter(languages):all(util.isin(installed)))
end
T["filter"]["warning"] = function()
    deps = vim.iter(installed):filter(util.notin(languages)):totable()
    if #deps == 0 then
        MiniTest.skip("no dependencies")
    end
    child.remove(deps)
    child.cmd("normal f")
    local warns = child.lua_get("vim.api.nvim_buf_get_lines(0, 0, -1, false)")
    eq(true, #warns > 0)
    if vim.iter({ "typescript", "glimmer_typescript" }):all(util.isin(languages)) then
        eq(
            true,
            vim.iter(warns):any(function(line)
                return line:match("glimmer_typescript")
            end)
        )
    end
end
T["filter"]["missing"] = function()
    child.cmd("normal f")
    local lines = child.lua_get("vim.api.nvim_buf_get_lines(0, 0, -1, false)")
    local missing = util.isin(vim.iter(lines)
        :map(function(line)
            return line:match("%S+")
        end)
        :totable())
    eq(false, vim.iter(languages):any(missing))
end
T["filter"]["all"] = function()
    child.cmd("normal f")
end

T["remove"] = function()
    child.works(languages, "parser")
    child.cmd("g/\\v^ *(" .. table.concat(languages, "|") .. ") /normal x")
    child.restart()
    child.fails(languages, "parser")
end

return T
