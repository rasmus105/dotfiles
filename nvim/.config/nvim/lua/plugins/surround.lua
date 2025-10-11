require('mini.surround').setup({
    mappings = {
        add = 'zh',       -- Add surrounding in Normal and Visual modes
        delete = 'ds',    -- Delete surrounding
        replace = 'zr',   -- Replace surrounding
        find = '',        -- Find surrounding (to the right)
        find_left = '',   -- Find surrounding (to the left)
        highlight = '',   -- Highlight surrounding

        suffix_last = '', -- Suffix to search with "prev" method
        suffix_next = '', -- Suffix to search with "next" method
    }
})
