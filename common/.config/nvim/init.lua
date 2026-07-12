vim.loader.enable()

---- Configuration (import order matters) ----
require("config.options") -- vim options (i.e. vim.opt.*)
require("config.keymaps") -- vim native keymaps
require("config.vim-pack")
require("config.colorscheme") -- colorscheme configuration and setup
require("config.diagnostics") -- diagnostic display configuration
require("config.lsp") -- LSP setup, configuration and keymaps
require("config.autocmds") -- Useful autocommands
require("config.commands") -- Useful autocommands
require("config.globals") -- Useful global functions

---- Iterate over all lua files in lua/plugins and import them ----
local plugin_files = vim.fn.readdir(vim.fn.stdpath("config") .. "/lua/plugins", [[v:val =~ '\.lua$']])
table.sort(plugin_files)

for _, file in ipairs(plugin_files) do
	local module = file:gsub("%.lua$", "")
	require("plugins." .. module)
end
