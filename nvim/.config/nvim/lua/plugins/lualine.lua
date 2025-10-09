local lualine = require('lualine')
local icons = require('mini.icons')

local config = {
    options = {
        component_separators = '',
        section_separators = '',
    },
    sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_y = {},
        lualine_z = {},
        lualine_c = {},
        lualine_x = {},
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_y = {},
        lualine_z = {},
        lualine_c = {},
        lualine_x = {},
    },
}

local function ins_left(component)
    table.insert(config.sections.lualine_c, component)
end

local function ins_right(component)
    table.insert(config.sections.lualine_x, component)
end

ins_left { 'mode' }

ins_left {
    function()
        return vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
    end,
    icon = ' ',
}

ins_left {
    function()
        local filename = vim.fn.expand('%:t')
        local extension = vim.fn.expand('%:e')
        local icon = icons.get('file', filename) or icons.get('extension', extension) or ''
        return string.format('%s %s', icon, filename)
    end,
    color = { gui = 'bold' },
}

ins_left { 'filesize' }

ins_left {
    'diagnostics',
    sources = { 'nvim_diagnostic' },
    symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' },
}

ins_right {
    'branch',
    icon = '',
}

ins_right {
    'diff',
    symbols = { added = ' ', modified = '󰜥 ', removed = ' ' },
}

ins_right {
    function()
        local msg = 'No Active Lsp'
        local buf_ft = vim.api.nvim_get_option_value('filetype', { buf = 0 })
        local clients = vim.lsp.get_clients()
        if next(clients) == nil then
            return msg
        end
        for _, client in ipairs(clients) do
            local filetypes = client.config.filetypes
            if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
                return client.name
            end
        end
        return msg
    end,
    icon = '  LSP:',
}

ins_right { 'encoding' }

ins_right { 'fileformat' }

ins_right { 'location' }

lualine.setup(config)
