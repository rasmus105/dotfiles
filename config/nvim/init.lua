local map = vim.keymap.set
---- Configuration ----
require("config.vim-pack")
require("config.options")     -- vim options (i.e. vim.opt.*)
require("config.vim-keymaps") -- vim native keymaps
require("config.colorscheme") -- colorscheme configuration and setup
require("config.lsp")         -- LSP setup, configuration and keymaps
require("config.autocmds")    -- Useful autocommands

---- Plugin ----
require("plugins.harpoon")
require("plugins.fzf-lua")
require("plugins.render-markdown")
require("plugins.lualine")
require("plugins.tabby")
require("plugins.surround")
require("plugins.vscode-diff")
require("plugins.gitsigns")

---- Misc Plugins With Minimal Configuration ----
-- icons
require("mini.icons").setup()
-- replacing stuff
require("grug-far").setup()
map("n", "<leader>z", function()
    require("grug-far").open()
end, { desc = "Search & Replace" })

-- file explorer
require("yazi").setup({
    floating_window_scaling_factor = 1,
    yazi_floating_window_zindex = 1,
    yazi_floating_window_border = "none", -- Remove border for true fullscreen
})
map("n", "<leader>-", ":Yazi<CR>", { desc = "Toggle Yazi" })

-- notification manager
require("notify").setup({
    render = "compact",
    stages = "slide",
    timeout = 2000,
    on_open = function(win)
        -- Use square corners
        vim.api.nvim_win_set_config(win, { border = "single" })
        -- Or remove the border entirely:
        -- vim.api.nvim_win_set_config(win, { border = "none" })
    end,
})
map("n", "<leader>.", function()
    require("notify").dismiss({ silent = true, pending = true })
end, { desc = "Dismiss notifications" })
map("n", "<leader>th", ":Notifications<CR>")

-- mini cursorword (underline current word)
require("mini.cursorword").setup({
    delay = 0,
})
