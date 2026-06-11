local installer = require("tree-sitter-manager.installer")
local ui = require("tree-sitter-manager.ui")

M._install_single = function(lang, callback)
    installer.install(lang, function(out)
        callback(out.ok)
    end, true, true)
end
M.open = ui.open
M._act = ui._act
