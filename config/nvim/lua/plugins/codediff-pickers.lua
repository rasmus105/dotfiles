local map = vim.keymap.set

-- Lightweight pickers that integrate fzf-lua with vscode-diff.nvim
-- Provides mappings:
--  - <leader>cg  : pick a repo commit and open :CodeDiff <commit>
--  - <leader>cf  : pick a commit from current file history and open :CodeDiff file <commit>
--  - <leader>cn  : open next commit from last picker
--  - <leader>cp  : open previous commit from last picker

local ok, fzf = pcall(require, "fzf-lua")
if not ok then
    vim.notify("vscode-diff-pickers: fzf-lua not found. Install/configure fzf-lua.", vim.log.levels.WARN)
    return
end

-- Module-local state for navigation
local state = {
    last_context = nil, -- "repo" or "file"
    repo = { list = {}, index = nil },
    file = { path = nil, list = {}, index = nil },
}

local function notify(msg, level)
    vim.notify(msg, level or vim.log.levels.INFO)
end

local function extract_hash(line)
    if not line then
        return nil
    end
    -- Strip ANSI escape sequences (fzf-lua may include colors) and trim whitespace
    local s = line:gsub("\27%[[0-9;]*m", ""):gsub("^%s+", ""):gsub("%s+$", "")
    -- Try to match a hex commit hash at start of the sanitized line
    local hash = s:match("^(%x+)") or s:match("^(%S+)")
    return hash
end

-- Find index of a hash in a list (supports short hash prefix matching)
local function find_hash_index(list, hash)
    if not list or not hash then
        return nil
    end
    for i, h in ipairs(list) do
        -- Exact match or prefix match (short hash matches full hash)
        if h == hash or h:sub(1, #hash) == hash or hash:sub(1, #h) == h then
            return i
        end
    end
    return nil
end

-- Utility: run git command in repo root and return lines or nil+err
local function git_lines(repo_root, args)
    if not repo_root or repo_root == "" then
        return nil, "no git repo"
    end
    -- Build command as a list to avoid shell tokenization issues
    local cmd = { 'git', '-C', repo_root }
    if type(args) == 'table' then
        for _, part in ipairs(args) do
            table.insert(cmd, part)
        end
    elseif type(args) == 'string' then
        for part in args:gmatch('%S+') do
            table.insert(cmd, part)
        end
    else
        return nil, "invalid args"
    end
    local out = vim.fn.systemlist(cmd)
    -- When git errors, systemlist returns error text; check v:shell_error
    if vim.v.shell_error ~= 0 then
        return nil, table.concat(out, '\n')
    end
    return out, nil
end

local function get_repo_root()
    local out = vim.fn.systemlist({ 'git', 'rev-parse', '--show-toplevel' })
    if vim.v.shell_error ~= 0 or not out or #out == 0 then
        return nil
    end
    return out[1]
end

local function build_repo_commit_list()
    local root = get_repo_root()
    if not root then
        return nil, "Not in a git repository"
    end
    -- Format includes hash and message to match fzf's output style
    local lines, err = git_lines(root, { '--no-pager', 'log', "--pretty=format:%H %s" })
    if not lines then
        return nil, err
    end
    local hashes = {}
    for _, l in ipairs(lines) do
        local h = extract_hash(l)
        if h then
            table.insert(hashes, h)
        end
    end
    return hashes, nil
end

local function build_file_commit_list(file_path)
    local root = get_repo_root()
    if not root then
        return nil, "Not in a git repository"
    end
    if not file_path or file_path == "" then
        return nil, "No file path"
    end
    -- Path relative to repo root
    local rel = file_path
    if file_path:sub(1, #root) == root then
        rel = file_path:sub(#root + 2) -- remove slash
    end
    local lines, err = git_lines(root, { '--no-pager', 'log', "--pretty=format:%H", '--', rel })
    if not lines then
        return nil, err
    end
    local hashes = {}
    for _, l in ipairs(lines) do
        local h = extract_hash(l)
        if h then
            table.insert(hashes, h)
        end
    end
    return hashes, nil
end

-- Close current tab if we have more than one tab (diff views open in new tabs)
local function close_current_tab_if_multiple()
    if vim.fn.tabpagenr('$') > 1 then
        vim.cmd("tabclose")
        return true
    end
    return false
end

local function open_repo_commit_by_index(idx)
    local list = state.repo.list
    if not list or #list == 0 then
        notify("No commit list available. Run the commit picker first.", vim.log.levels.WARN)
        return
    end
    if idx < 1 or idx > #list then
        notify("No more commits.", vim.log.levels.WARN)
        return
    end
    state.repo.index = idx
    local hash = list[idx]

    -- Close current diff tab if open, then open new one
    close_current_tab_if_multiple()
    vim.schedule(function()
        vim.cmd("CodeDiff " .. hash .. "^ " .. hash)
    end)
end

local function open_file_commit_by_index(idx)
    local list = state.file.list
    if not list or #list == 0 then
        notify("No file commit list available. Run the file commit picker first.", vim.log.levels.WARN)
        return
    end
    if idx < 1 or idx > #list then
        notify("No more commits.", vim.log.levels.WARN)
        return
    end
    state.file.index = idx
    local hash = list[idx]

    -- Close current diff tab if open, then open new one
    close_current_tab_if_multiple()
    vim.schedule(function()
        vim.cmd("CodeDiff file " .. hash .. "^ " .. hash)
    end)
end

-- Navigation API
-- Note: git log lists newest commits first, so:
--   - "next" (newer in time) = lower index
--   - "prev" (older in time) = higher index

local function next_commit()
    if state.last_context == "file" then
        if not state.file.index then
            notify("No file commit selected. Run file picker first.", vim.log.levels.WARN)
            return
        end
        local idx = state.file.index - 1
        open_file_commit_by_index(idx)
    else
        -- repo context
        if not state.repo.index then
            notify("No commit selected. Run commit picker first.", vim.log.levels.WARN)
            return
        end
        local idx = state.repo.index - 1
        open_repo_commit_by_index(idx)
    end
end

local function prev_commit()
    if state.last_context == "file" then
        if not state.file.index then
            notify("No file commit selected. Run file picker first.", vim.log.levels.WARN)
            return
        end
        local idx = state.file.index + 1
        open_file_commit_by_index(idx)
    else
        if not state.repo.index then
            notify("No commit selected. Run commit picker first.", vim.log.levels.WARN)
            return
        end
        local idx = state.repo.index + 1
        open_repo_commit_by_index(idx)
    end
end

-- Pickers
local function pick_repo_commit()
    -- Build and store commit list to support navigation
    local hashes, err = build_repo_commit_list()
    if not hashes then
        notify("Could not build commit list: " .. tostring(err), vim.log.levels.ERROR)
        return
    end
    state.repo.list = hashes
    state.repo.index = nil
    state.last_context = "repo"

    fzf.git_commits({
        prompt = "Commits> ",
        actions = {
            ["default"] = function(selected)
                vim.schedule(function()
                    if #selected > 0 then
                        local hash = extract_hash(selected[1])
                        if hash then
                            -- find index in stored list (supports short hash)
                            local idx = find_hash_index(state.repo.list, hash)
                            state.repo.index = idx
                            -- Use full hash from list if found
                            local full_hash = (idx and state.repo.list[idx]) or hash
                            vim.cmd("CodeDiff " .. full_hash .. "^ " .. full_hash)
                        else
                            notify("Could not parse commit hash", vim.log.levels.ERROR)
                        end
                    end
                end)
            end,
        },
    })
end

local function pick_file_commit()
    local file_path = vim.api.nvim_buf_get_name(0)
    if file_path == nil or file_path == "" then
        notify("Current buffer has no file path", vim.log.levels.ERROR)
        return
    end
    local hashes, err = build_file_commit_list(file_path)
    if not hashes then
        notify("Could not build file commit list: " .. tostring(err), vim.log.levels.ERROR)
        return
    end
    state.file.path = file_path
    state.file.list = hashes
    state.file.index = nil
    state.last_context = "file"

    fzf.git_bcommits({
        prompt = "File Commits> ",
        actions = {
            ["default"] = function(selected)
                vim.schedule(function()
                    if #selected > 0 then
                        local hash = extract_hash(selected[1])
                        if hash then
                            -- find index in stored list (supports short hash)
                            local idx = find_hash_index(state.file.list, hash)
                            state.file.index = idx
                            -- Use full hash from list if found
                            local full_hash = (idx and state.file.list[idx]) or hash
                            vim.cmd("CodeDiff file " .. full_hash .. "^ " .. full_hash)
                        else
                            notify("Could not parse commit hash", vim.log.levels.ERROR)
                        end
                    end
                end)
            end,
        },
    })
end

-- Keymaps
map("n", "<leader>cg", pick_repo_commit, { desc = "Pick repo commit and open CodeDiff" })
map("n", "<leader>cf", pick_file_commit, { desc = "Pick current file commit and open CodeDiff" })
map("n", "<leader>cn", next_commit, { desc = "Open next commit from last picker" })
map("n", "<leader>cp", prev_commit, { desc = "Open previous commit from last picker" })
