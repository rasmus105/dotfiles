-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd([[packadd packer.nvim]])

return require("packer").startup(function(use)
	-- Packer can manage itself
	use("wbthomason/packer.nvim")
	use({ "nvim-tree/nvim-web-devicons" })
	use({
		"nvim-telescope/telescope.nvim",
		tag = "0.1.6",
		requires = {
			"nvim-lua/plenary.nvim",
			"duane9/nvim-rg",
		},
	})
	-- use {
	-- 'nvim-telescope/telescope-file-browser.nvim', -- not working for some reason
	-- requires = {
	--     "nvim-telescope/telescope.nvim",
	--     "nvim-lua/plenary.nvim"
	-- }
	--   }
	use({
		"ellisonleao/gruvbox.nvim",
	})
	use({
		"rebelot/kanagawa.nvim",
	})
	use({
		"kepano/flexoki-neovim",
	})
	use({
		"HoNamDuong/hybrid.nvim",
	})
	use({
		"jacoborus/tender.vim",
	})
	use({
		"ribru17/bamboo.nvim",
	})
	use("nvim-treesitter/nvim-treesitter", { run = ":TSUpdate" })
	use("nvim-treesitter/playground")
	use({
		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",
		-- follow latest release.
		tag = "v2.3.0", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
		-- install jsregexp (optional!:).
		run = "make install_jsregexp",
	})

	use({
		"VonHeikemen/lsp-zero.nvim",
		branch = "v3.x",
		requires = {
			--- Uncomment these if you want to manage LSP servers from neovim
			-- {'williamboman/mason.nvim'},
			-- {'williamboman/mason-lspconfig.nvim'},

			-- LSP Support
			{ "williamboman/mason.nvim" },
			{ "williamboman/mason-lspconfig.nvim" },
			{ "neovim/nvim-lspconfig" },
			{ "neovim/nvim-lspconfig" },
			-- Autocompletion
			{ "hrsh7th/nvim-cmp" },

			{ "hrsh7th/cmp-buffer" },
			{ "hrsh7th/cmp-path" },
			{ "hrsh7th/cmp-cmdline" },
			{ "hrsh7th/cmp-nvim-lsp" },
			-- { "hrsh7th/vim-vsnip" },

			{ "L3MON4D3/LuaSnip" },
			{ "rafamadriz/friendly-snippets" },
		},
	})
	use({
		"mfussenegger/nvim-dap",
		"rcarriga/nvim-dap-ui",
		"theHamsta/nvim-dap-virtual-text",
		"leoluz/nvim-dap-go",
		"nvim-neotest/nvim-nio",
	})
	use({
		"nvim-lualine/lualine.nvim",
		requires = { "nvim-tree/nvim-web-devicons", opt = true },
	})
	use({
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	})
	-- Lua
	use({
		"folke/which-key.nvim",
		config = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
			require("which-key").setup({
				-- your configuration comes here
				-- or leave it empty to use the default settings
				-- refer to the configuration section below
			})
		end,
	})
	use({
		"windwp/nvim-autopairs",
		config = function()
			require("nvim-autopairs").setup({})
		end,
	})
	use({
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		requires = { { "nvim-lua/plenary.nvim" } },
	})
	-- use({
	-- 	"romgrk/barbar.nvim",
	-- 	"lewis6991/gitsigns.nvim",
	-- 	-- 'nvim-tree/nvim-web-devicons',
	-- })
	use({
		"WhoIsSethDaniel/toggle-lsp-diagnostics.nvim",
	})
	use({
		"kawre/leetcode.nvim",
		-- {run=":TSUpdate html"},
		-- build = "TSUpdate html,
		requires = {
			"nvim-telescope/telescope.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",

			-- optional
			-- 'nvim-treesitter/nvim-treesitter',
			-- 'rcarriga/nvim-notify',
			-- 'nvim-tree/nvim-web-devicons'
		},
	})
	use("lervag/vimtex")
	use("mhartington/formatter.nvim")

	use({
		"kylechui/nvim-surround",
		tag = "*",
		config = function()
			require("nvim-surround").setup({})
		end,
	})
	use({
		"kevinhwang91/nvim-ufo",
		requires = "kevinhwang91/promise-async",
	})
	use({
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
	})
end)
