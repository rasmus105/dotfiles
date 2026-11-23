-- Let terminal applications handle Control+Tab.
rex.unbind("ctrl+tab")

-- A separate script can observe the native New Tab action after this action returns.
local place_new_tab = [[
  local original = rex.args.windows
  for attempt = 1, 20 do
    local view = rex.session.view{}
    if not view or #view.windows < #original or #view.windows > #original + 1 then
      return
    end
    for index, window_id in ipairs(original) do
      if view.windows[index].window_id ~= window_id then
        return
      end
    end

    local added = view.windows[#original + 1]
    if added and added.window_id == view.active_window_id then
      rex.session.move_window{
        window_id = added.window_id,
        before_window_id = rex.args.before_window_id,
      }
      return
    end
    rex.sleep(0.05)
  end
]]

rex.action{
  name = "new_tab_beside",
  title = "New Tab Beside Current Tab",
  run = function(ctx)
    rex.client.queue("client.tab.new")
    if not ctx.session_id then
      return
    end

    local view = rex.session.view{}
    if not view then
      return
    end
    local windows = {}
    local active_index, focused_index
    for index, window in ipairs(view.windows) do
      windows[index] = window.window_id
      if ctx.block_id and window.focused_block_id == ctx.block_id then
        focused_index = index
      end
      if window.window_id == view.active_window_id then
        active_index = index
      end
    end
    local current_index = focused_index or active_index
    local before_window_id = current_index and windows[current_index + 1]
    if not before_window_id then
      return
    end

    local args = rex.json.encode({ windows = windows, before_window_id = before_window_id })
    local command = { "rex", "--autostart=false", "--timeout", "2s" }
    if ctx.server then
      command[#command + 1] = "-S"
      command[#command + 1] = ctx.server
    end
    for _, arg in ipairs({ "do", "-s", ctx.session_id, "-e", place_new_tab, "--args", args }) do
      command[#command + 1] = arg
    end
    local options = { detach = true, timeout = 4, env = { REX_SERVER = false, REX_BLOCK = false } }
    if not rex.exec.start(command, options) and os.getenv("HOME") then
      command[1] = os.getenv("HOME") .. "/Library/Application Support/com.superlogical.rex/"
        .. "RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
      rex.exec.start(command, options)
    end
  end,
}
rex.bind("cmd+t", "new_tab_beside")

rex.bind("shift+cmd+k", "toggle_session_pair")
rex.bind("alt+cmd+k", "pick_alternate_session")

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
