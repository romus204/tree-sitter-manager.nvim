-- Update parsers to latest version (tier 1, stable) or commit (tier 2, unstable)
local util = require("tree-sitter-manager.util")
local parsers = require("tree-sitter-manager.repos")
local old_parsers = vim.deepcopy(parsers)

local M = {}

---@param message string
---@param level? number traceback level
---@param stay? boolean if true don't exit Neovim session
local function error(message, level, stay)
    level = level or 2
    local trace = debug.traceback(tostring(message), level)
    io.write("error: " .. trace .. "\n")
    if not stay then
        os.exit(1)
    end
end

function M.update()
    local jobs = {} ---@type table<string,AsyncJob>
    local updates = {} ---@type string[]

    -- check for new revisions
    io.write("Updating")
    for name, parser in pairs(parsers) do
        if parser.tier and parser.tier <= 2 and parser.install_info then
            local cmd = parser.tier == 1
                    and {
                        "git",
                        "-c",
                        "versionsort.suffix=-",
                        "ls-remote",
                        "--tags",
                        "--refs",
                        "--sort=v:refname",
                        parser.install_info.url,
                    }
                or { "git", "ls-remote", parser.install_info.url }

            jobs[name] = util.run(cmd, { callback = function() end }) -- empty callback to force-batch calls
        end
    end

    for name, job in pairs(jobs) do
        local status = job:wait(60000)
        if not status.ok then
            io.write("\n" .. name .. " " .. (status.error or "") .. "\n")
        else
            io.write(" " .. name)

            local parser = parsers[name]
            local stdout = vim.split(status.output or "", "\n")
            local sha ---@type string?

            if parser.tier == 1 then
                sha = stdout[#stdout - 1] and stdout[#stdout - 1]:match("v[%d%.]+$")
            else
                local branch = parser.install_info.branch
                local line = vim.iter(stdout):find(function(line)
                    return branch and line:find(vim.pesc(branch))
                end) or stdout[1]
                sha = line and vim.split(line, "\t")[1]
            end

            if sha and sha ~= "" and parser.install_info.revision ~= sha then
                parser.install_info.revision = sha
                table.insert(updates, name)
            end
        end
        io.flush()
    end
    io.write("\n")

    if #updates == 0 then
        io.write("\nAll parsers up to date!\n")
    else
        io.write("\nUpdates: " .. table.concat(updates, " ") .. "\n")
        M._update(updates)
    end
end

function M._update(languages)
    local status

    status = util.run({ "git", "checkout", "-B", "auto-updated-parsers" }):wait()
    if not status.ok then
        error(status.error)
    end

    status = util.run({ "git", "reset", "main" }):wait()
    if not status.ok then
        error(status.error)
    end

    M._write_repos(parsers)

    -- test updated repos
    _G.languages = languages
    local reporter = MiniTest.gen_reporter.stdout()

    MiniTest.run_file("tests/test_all_queries.lua", {
        execute = {
            reporter = {
                start = reporter.start,
                update = reporter.update,
                finish = M._finish,
            },
        },
    })
end

---@param parsers table<string,tree_sitter_manager.LanguageSpec>
function M._write_repos(parsers)
    local header = table.concat({
        "---@class tree_sitter_manager.LanguageSpec",
        "---@field install_info? tree_sitter_manager.InstallInfo Information about how to fetch and build the grammar.",
        "---@field requires? string[] Other languages that are dependencies of this one and must be installed first.",
        "---@field tier? number tier 1 updates to the latest version, tier 2 updates to the latest commit",
        "",
        "---@class tree_sitter_manager.InstallInfo",
        "---@field url string Git URL of the grammar repository.",
        "---@field location? string Sub-directory within the repo where the grammar is stored. Defaults to the name of the language.",
        "---@field revision? string Git revision to check out after cloning. Takes priority over `branch`.",
        "---@field branch? string Git branch to check out after cloning. Ignored if `revision` is set.",
        "---@field generate? boolean Run `tree-sitter generate` before building. Defaults to false.",
        "---@field queries? string Specifies the queries directory in the cloned repo that will be used.",
        "",
        "---@type table<string,tree_sitter_manager.LanguageSpec>",
        "return ",
    }, "\n")
    local repos_content = header .. vim.inspect(parsers)
    if vim.fn.executable("stylua") == 1 then
        repos_content = util.run({ "stylua", "-" }, { stdin = repos_content }):wait().output --[[@as string]]
    end
    local repos = io.open("lua/tree-sitter-manager/repos.lua", "w")
    if not repos then
        error("could not open repos.lua for writing")
    end
    repos:write(repos_content)
    repos:close()
end

---PR passed parsers, and Report failed parsers
function M._finish()
    local cases = MiniTest.current.all_cases
    local parser_state = {}

    for _, case in ipairs(cases) do
        local language = case.args[1]
        if not case.exec then
        elseif case.exec.state == "Pass" and parser_state[language] ~= false then
            parser_state[language] = true
        elseif case.exec.state == "Fail" then
            parser_state[language] = false
        end
    end

    local passed = vim.iter(parser_state)
        :map(function(language, passed)
            return passed and language or nil
        end)
        :totable()

    local failed = vim.iter(parser_state)
        :map(function(language, passed)
            return not passed and language or nil
        end)
        :totable()

    for _, language in ipairs(failed) do
        parsers[language] = old_parsers[language]
    end

    M._write_repos(parsers)

    local exit_code = 0

    if #passed > 0 then
        table.sort(passed)
        io.write("\nPushing passed parsers:\n" .. table.concat(passed, " ") .. "\n")
        exit_code = M._push_passed(passed)
    end

    if #failed > 0 then
        table.sort(failed)
        io.write("\nReporting failed parsers:\n" .. table.concat(failed, " ") .. "\n")
        M._report_failed(vim.iter(cases)
            :filter(function(case)
                return case.exec and vim.startswith(case.exec.state, "Fail")
            end)
            :totable())
        exit_code = 1
    end

    os.exit(exit_code)
end

function M._push_passed(languages)
    vim.env.XDG_CONFIG_HOME = nil
    vim.env.XDG_DATA_HOME = nil
    vim.env.XDG_STATE_HOME = nil

    local status

    status = util.run({ "git", "add", "lua/tree-sitter-manager/repos.lua" }):wait()
    if not status.ok then
        error(status.error)
    end

    status = util.run({ "git", "commit", "-m", "chore(repos): update revisions\n\n" .. table.concat(languages, " ") })
        :wait()
    if not status.ok then
        error(status.error)
    end

    status = util.run({ "git", "push", "-f", "-u", "origin", "auto-updated-parsers" }):wait()
    if not status.ok then
        error(status.error)
    end

    local content = { "--title", "chore(repos): update revisions", "--body", table.concat(languages, " ") }
    status = util.run({ "gh", "pr", "create", "--label", "automated", unpack(content) }):wait()
    if not status.ok and status.error and status.error:match("already exists") then
        io.write("\nPull request exists! Updating its body\n")
        status = util.run({ "gh", "pr", "edit", "auto-updated-parsers", unpack(content) }):wait()
    end
    if not status.ok then
        error(status.error, nil, true)
        return 1
    end
    return 0
end

function M._report_failed(cases)
    local issues = vim.iter(cases):fold(
        vim.defaulttable(function()
            return {}
        end),
        function(issues, case)
            vim.list_extend(issues[case.args[1]], case.exec.fails)
            return issues
        end
    )

    for language, issue in pairs(issues) do
        io.write("\n" .. language .. "\n")
        io.write(table.concat(issue, "\n") .. "\n----------------------------\n")
    end
end

return M
