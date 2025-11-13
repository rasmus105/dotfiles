local map = vim.keymap.set

local harpoon = require("harpoon")
harpoon.setup({
    settings = {
        save_on_toggle = true,
        sync_on_ui_close = true,
    },
})

local harpoon_list = harpoon:list()

harpoon:extend(require("harpoon.extensions").builtins.highlight_current_file())

-- Override the default menu UI to add number key mappings
local orig_ui_toggle = harpoon.ui.toggle_quick_menu
harpoon.ui.toggle_quick_menu = function(...)
    orig_ui_toggle(...)

    -- Get the harpoon window/buffer if it exists
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win)
    local bufname = vim.api.nvim_buf_get_name(buf)

    -- Check if this is the harpoon menu
    if bufname:match("harpoon") then
        -- Map 1-9 keys in the harpoon buffer
        for i = 1, 9 do
            map(
                "n",
                tostring(i),
                function()
                    harpoon_list:select(i)
                end,
                { buffer = buf, noremap = true, silent = true }
            )
        end
    end
end

-- Harpoon
map("n", "<leader>h", function()
    harpoon_list:add()
end)

map("n", "<S-h>", function()
    harpoon.ui:toggle_quick_menu(harpoon_list)
end)

for i = 1, 9 do
    map("n", "<leader>" .. i, function()
        harpoon_list:select(i)
    end)
end

