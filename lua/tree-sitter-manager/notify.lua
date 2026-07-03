local config = require("tree-sitter-manager.config")

---@alias NotifyIcon
---| "removed"  # Something was removed.
---| "install"  # An install is in progress.
---| "update"   # An update is in progress.
---| "warning"  # Something went wrong.
---| "success"  # An operation finished successfully.
---| "generate" # A generation step is in progress.
---| "build"    # A build step is in progress.

---@type table<NotifyIcon, string>
local icons = {
    removed = "✕ ",
    install = "📦 ",
    update = "󰚰 ",
    warning = "⚠ ",
    success = "✓ ",
    generate = "⚙️ ",
    build = "🔨 ",
}

local M = {}

---@class NotifyOpts
---@field icon?  NotifyIcon Prefix the message with this icon (nerdfont only).
---@field level? integer    Log level forwarded to |vim.notify()| (e.g. `vim.log.levels.WARN`).

---Display a notification, optionally prefixed with an icon.
---@param message string      The notification message.
---@param opts?   NotifyOpts  Optional settings selecting an icon and log level.
function M.notify(message, opts)
    opts = opts or {}
    local prefix = ""
    if opts.icon and config.cfg.nerdfont then
        prefix = icons[opts.icon] or ""
    end
    vim.notify(prefix .. message, opts.level)
end

return M
