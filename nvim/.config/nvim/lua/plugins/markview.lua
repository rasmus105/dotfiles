local map = vim.keymap.set

require('markview').setup({
    typst = {
        enabled = false,
    },
})

map('n', '<leader>tm', ':Markview Toggle<CR>', { desc = "Toggle Markview" })
