local languages = _G.languages or { "tsv", "tsx" }

local T = new_set()

T["TSInstall"] = function()
    child.cmd("TSInstall " .. table.concat(languages, " "))
    child.wait(languages)
    child.works(languages)
end

T["TSUpdate"] = function()
    child.works(languages)
    child.cmd("TSUpdate " .. table.concat(languages, " "))
    eq(false, child.lua_get("vim.iter(" .. vim.inspect(languages) .. "):any(util.is_installed)"))
    child.wait(languages)
    child.works(languages)
end

T["TSUninstall"] = function()
    child.cmd("TSUninstall " .. table.concat(languages, " "))
    child.restart()
    child.fails(languages)
end

return T
