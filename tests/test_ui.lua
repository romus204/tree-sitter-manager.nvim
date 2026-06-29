local languages = _G.languages or { "tsv", "tsx" }

local T = new_set()

T["open"] = function()
    child.cmd("TSManager")
end

T["install"] = function()
    child.cmd("g/\\v^ *(" .. table.concat(languages, "|") .. ")/normal i")
    child.wait(languages)
    child.works(languages)
end

T["update"] = function()
    child.works(languages)
    child.cmd("g/\\v^ *(" .. table.concat(languages, "|") .. ")/normal u")
    eq(
        false,
        child.lua_get("vim.iter(" .. vim.inspect(languages) .. [[):filter(function(lang)
            return not util.is_only_query(lang)
        end):any(util.is_installed)]])
    )
    child.wait(languages)
    child.works(languages)
end

T["remove"] = function()
    child.works(languages)
    child.cmd("g/\\v^ *(" .. table.concat(languages, "|") .. ")/normal x")
    child.restart()
    child.fails(languages)
end

return T
