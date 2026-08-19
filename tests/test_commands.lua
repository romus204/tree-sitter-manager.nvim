local languages = languages or { "tsv", "tsx" }

local T = new_set()

T.TSInstall = function()
    child.wait_removed(languages)
    child.cmd("TSInstall " .. table.concat(languages, " "))
    child.wait_installed(languages)
end

T.TSUpdate = function()
    child.wait_installed(languages)
    child.cmd("TSUpdate " .. table.concat(languages, " "))
    child.wait_installed(languages)
end

T["TSUpdate!"] = function()
    child.wait_installed(languages)
    child.cmd("TSUpdate!")
    child.wait_installed(languages)
end

T.TSUninstall = function()
    child.wait_installed(languages)
    child.cmd("TSUninstall " .. table.concat(languages, " "))
    child.wait_removed(languages)
end

return T
