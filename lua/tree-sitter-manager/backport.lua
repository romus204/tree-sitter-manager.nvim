local installer = require("tree-sitter-manager.installer")
local ui = require("tree-sitter-manager.ui")

local M = {
    _install_single = function(lang, callback)
        installer.install(lang, function(out)
            callback(out.ok)
        end, true, true)
    end,
    open = ui.open,
    _act = ui._act,
}

return M
