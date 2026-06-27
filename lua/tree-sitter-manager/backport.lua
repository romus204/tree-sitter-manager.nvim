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

function M.backport_use_repo_queries(info)
    if info.use_repo_queries then
        info.queries = info.queries or "queries"
    elseif info.use_repo_queries == false then
        info.queries = nil
    end
    info.use_repo_queries = nil
    return info
end

return M
