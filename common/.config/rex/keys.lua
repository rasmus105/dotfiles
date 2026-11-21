-- Let terminal applications handle Control+Tab.
rex.unbind("ctrl+tab")

rex.action{
  name = "new_tab_beside",
  title = "New Tab Beside Current Tab",
  run = function(ctx)
    if not ctx.session_id then
      rex.client.queue("client.tab.new")
      return
    end

    local view = assert(rex.session.view{})
    local current_index
    for index, window in ipairs(view.windows) do
      if ctx.block_id and window.focused_block_id == ctx.block_id then
        current_index = index
        break
      end
      if window.window_id == view.active_window_id then
        current_index = index
      end
    end
    local next_window = current_index and view.windows[current_index + 1]

    local cwd
    if ctx.block_id then
      local directory = rex.block.call("com.superlogical.terminal", "pwd", { block_id = ctx.block_id })
      if directory and directory.pwd then
        local path = directory.pwd:match("^file://[^/]*(/.*)$")
        cwd = path and path:gsub("%%(%x%x)", function(hex)
          return string.char(tonumber(hex, 16))
        end)
      end
    end
    local tab = assert(rex.session.new_window{
      focus = false,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        options = { cwd = cwd },
      },
    })

    if next_window then
      assert(rex.session.move_window{
        window_id = tab.window_id,
        before_window_id = next_window.window_id,
      })
    end

    -- Let the app handle focus within its current session, including on remote hosts.
    rex.client.queue("client.tab.goto", { index = next_window and current_index + 1 or -1 })
  end,
}
rex.bind("cmd+t", "new_tab_beside")

-- rex.bind("cmd+k", "pick_session")
rex.bind("shift+cmd+k", "session.recent")

-- Adding Command distinguishes Rex panes from Neovim's Control shortcuts.
rex.bind("cmd+ctrl+h", "pane.focus", { direction = "left" })
rex.bind("cmd+ctrl+j", "pane.focus", { direction = "down" })
rex.bind("cmd+ctrl+k", "pane.focus", { direction = "up" })
rex.bind("cmd+ctrl+l", "pane.focus", { direction = "right" })

rex.bind("cmd+ctrl+v", "pane.split", { direction = "right" })
rex.bind("cmd+ctrl+s", "pane.split", { direction = "down" })

rex.bind("cmd+ctrl+f", "pane.zoom")

-- Send literal bytes, matching Ghostty even with extended key protocols enabled.
rex.bind("ctrl+[", "com.superlogical.terminal.write", { data = "\027" })
rex.bind("ctrl+enter", "com.superlogical.terminal.write", { data = "\r" })
