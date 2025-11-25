---- Colorscheme configuration ----

require("gruvbox").setup({
    terminal_colors = true, -- add neovim terminal colors
    undercurl = true,
    underline = true,
    bold = true,
    italic = {
        strings = false,
        emphasis = true,
        comments = true,
        operators = false,
        folds = true,
    },
    strikethrough = true,
    invert_selection = false,
    invert_signs = false,
    invert_tabline = false,
    invert_intend_guides = false,
    inverse = true, -- invert background for search, diffs, statuslines and errors
    contrast = "",  -- can be 'hard', 'soft' or empty string
    palette_overrides = {},
    dim_inactive = false,
    transparent_mode = false,
    overrides = {
        Normal = { bg = "#292522" },
    },
})

require("monokai-pro").setup({
    filter = "ristretto",
    override = function()
        return {
            NonText = { fg = "#948a8b" },
            MiniIconsGrey = { fg = "#948a8b" },
            MiniIconsRed = { fg = "#fd6883" },
            MiniIconsBlue = { fg = "#85dacc" },
            MiniIconsGreen = { fg = "#adda78" },
            MiniIconsYellow = { fg = "#f9cc6c" },
            MiniIconsOrange = { fg = "#f38d70" },
            MiniIconsPurple = { fg = "#a8a9eb" },
            MiniIconsAzure = { fg = "#a8a9eb" },
            MiniIconsCyan = { fg = "#85dacc" }, -- same value as MiniIconsBlue for consistency
        }
    end,
})

---- Select the default colorscheme ----

local uv = vim.uv or vim.loop
local theme_file = vim.fn.expand("~/.config/nvim/theme.lua")
local light_mode_file = vim.fn.expand("~/.config/theme/light.mode")

local function apply_theme()
    -- Set Vim background based on presence of light.mode marker file
    if vim.fn.filereadable(light_mode_file) == 1 then
        vim.o.background = "light"
    else
        vim.o.background = "dark"
    end

    local ok, theme = pcall(dofile, theme_file)
    if ok and type(theme) == "table" and theme.colorscheme then
        local colorscheme = theme.colorscheme
        local ok_cs, err = pcall(vim.cmd.colorscheme, colorscheme)
        if not ok_cs then
            vim.notify("Failed to set colorscheme '" .. colorscheme .. "': " .. err, vim.log.levels.ERROR)
        end
    else
        vim.notify("Failed to load theme.lua", vim.log.levels.ERROR)
    end
end

-- Apply on startup
apply_theme()

-- Watch for external changes by polling the symlink target
-- fs_event doesn't work well with symlinks, so we poll instead
-- Using 1000 ms interval - very low overhead
local last_target = vim.fn.resolve(theme_file)
local timer = uv.new_timer()
timer:start(1000, 1000, vim.schedule_wrap(function()
    local current_target = vim.fn.resolve(theme_file)
    if current_target ~= last_target then
        last_target = current_target
        apply_theme()
    end
end))

-- Optional manual command if you ever want to trigger it yourself
vim.api.nvim_create_user_command("ThemeReload", apply_theme, {})
