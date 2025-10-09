require('fff').setup({})

vim.g.fff = {
    lazy_sync = true, -- start syncing only when the picker is open
    prompt = "> ",    -- default icon isn't loaded properly
    debug = {
        enabled = false,
        show_scores = true,
    },
}

