local M = {}

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
