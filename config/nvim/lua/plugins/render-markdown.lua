local map = vim.keymap.set

require('render-markdown').setup({})

map('n', '<leader>tm', ':RenderMarkdown toggle<CR>', { desc = "Toggle Markdown Rendering" })
