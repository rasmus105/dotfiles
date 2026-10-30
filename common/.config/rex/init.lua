-- Let terminal applications handle Control+Tab.
rex.unbind("ctrl+tab")

-- Adding Command distinguishes Rex panes from Neovim's Control shortcuts.
rex.bind("cmd+ctrl+h", "pane.focus", { direction = "left" })
rex.bind("cmd+ctrl+j", "pane.focus", { direction = "down" })
rex.bind("cmd+ctrl+k", "pane.focus", { direction = "up" })
rex.bind("cmd+ctrl+l", "pane.focus", { direction = "right" })

rex.bind("cmd+ctrl+v", "pane.split", { direction = "right" })
rex.bind("cmd+ctrl+s", "pane.split", { direction = "down" })

-- Send literal bytes, matching Ghostty even with extended key protocols enabled.
rex.bind("ctrl+[", "com.superlogical.terminal.write", { data = "\027" })
rex.bind("ctrl+enter", "com.superlogical.terminal.write", { data = "\r" })
