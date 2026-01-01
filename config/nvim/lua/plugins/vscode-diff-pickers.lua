local map = vim.keymap.set

-- Lightweight pickers that integrate fzf-lua with vscode-diff.nvim
-- Provides two mappings:
--  - <leader>cg  : pick a repo commit and open :CodeDiff <commit>
--  - <leader>cf  : pick a commit from current file history and open :CodeDiff file <commit>

local ok, fzf = pcall(require, "fzf-lua")
if not ok then
    vim.notify("vscode-diff-pickers: fzf-lua not found. Install/configure fzf-lua.", vim.log.levels.WARN)
    return
end

local function extract_hash(line)
    if not line then
        return nil
    end
    -- Try to match a hex commit hash at start of line
    local hash = line:match("^(%x+)") or line:match("^(%S+)")
    return hash
end

local function pick_repo_commit()
    fzf.git_commits({
        prompt = "Commits> ",
        actions = {
            ["default"] = function(selected)
                vim.schedule(function()
                    if #selected > 0 then
                        local hash = extract_hash(selected[1])
                        if hash then
                            vim.cmd("CodeDiff " .. hash)
                        else
                            vim.notify("Could not parse commit hash", vim.log.levels.ERROR)
                        end
                    end
                end)
            end,
        },
    })
end

local function pick_file_commit()
    fzf.git_bcommits({
        prompt = "File Commits> ",
        actions = {
            ["default"] = function(selected)
                vim.schedule(function()
                    if #selected > 0 then
                        local hash = extract_hash(selected[1])
                        if hash then
                            vim.cmd("CodeDiff file " .. hash)
                        else
                            vim.notify("Could not parse commit hash", vim.log.levels.ERROR)
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
