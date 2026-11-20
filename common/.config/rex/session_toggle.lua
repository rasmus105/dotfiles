local session_navigation = require("session_navigation")

-- Rex keeps several sessions attached per client, so attachment events
-- cannot identify which session the app was showing before a host switch.
local alternate_by_client = {}

rex.action{
  name = "remember_session",
  title = "Remember Session for Toggle",
  run = function(ctx)
    if ctx.client_id and ctx.session_id then
      alternate_by_client[ctx.client_id] = { id = ctx.session_id, server = ctx.server }
    end
  end,
}

rex.action{
  name = "toggle_session",
  title = "Toggle Remembered Session",
  run = function(ctx)
    local alternate = alternate_by_client[ctx.client_id]
    if not alternate or not ctx.session_id
      or (alternate.id == ctx.session_id and alternate.server == ctx.server) then
      rex.client.queue("session.recent")
      return
    end

    session_navigation.select_session(ctx, alternate.id, alternate.server)
    alternate_by_client[ctx.client_id] = { id = ctx.session_id, server = ctx.server }
  end,
}
