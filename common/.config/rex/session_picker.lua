local session_navigation = require("session_navigation")

-- Rex exposes history navigation as a focus change. Track the sessions seen
-- by this picker in memory for the lifetime of the loaded config.
local visit_order = {}
local visit_count = 0

-- Host settings can store SF Symbols, but rex.ui.pick accepts a fixed set.
local picker_icons = {
  document = true,
  folder = true,
  branch = true,
  terminal = true,
  code = true,
  server = true,
  database = true,
  package = true,
  globe = true,
  link = true,
  person = true,
  tag = true,
  clock = true,
  star = true,
  gear = true,
  plus = true,
}

local function record_visit(session_id)
  visit_count = visit_count + 1
  visit_order[session_id] = visit_count
end

rex.action{
  name = "pick_session",
  title = "Pick Recent Session",
  run = function(ctx)
    if not rex.ui then
      rex.client.queue("session.switch")
      return
    end

    if ctx.session_id then
      record_visit(ctx.session_id)
    end

    local icon_by_host = {}
    local call_home = ctx.server and session_navigation.home_call or rex.call
    local host_list = call_home("hosts.list")
    for _, host in ipairs(host_list and host_list.hosts or {}) do
      if picker_icons[host.icon] then
        icon_by_host[host.label:lower()] = host.icon
      end
    end

    local items = {}
    local session_hosts = {}
    local function add_sessions(server, result, err)
      local host = server or "This Mac"
      if not result then
        rex.log("warn", "Session picker (" .. host .. "): " .. (err or "session list unavailable"))
        return
      end
      for _, session in ipairs(result.sessions or {}) do
        local id = session.session_id
        if id ~= ctx.session_id and session_hosts[id] == nil then
          session_hosts[id] = server or false
          items[#items + 1] = {
            id = id,
            title = session.label ~= "" and session.label or id,
            subtitle = host,
            icon = icon_by_host[host:lower()],
            detail = visit_order[id] and "Recent" or nil,
          }
        end
      end
    end

    if ctx.server then
      add_sessions(nil, session_navigation.home_call("session.list"))
    end
    add_sessions(ctx.server, rex.call("session.list"))
    for _, server in ipairs(rex.servers()) do
      if server ~= ctx.server then
        add_sessions(server, rex.server(server).call("session.list"))
      end
    end

    if #items == 0 then
      rex.client.queue("session.switch")
      return
    end

    table.sort(items, function(a, b)
      local a_visit = visit_order[a.id] or 0
      local b_visit = visit_order[b.id] or 0
      if a_visit ~= b_visit then
        return a_visit > b_visit
      end
      local a_title = a.title:lower()
      local b_title = b.title:lower()
      if a_title ~= b_title then
        return a_title < b_title
      end
      if a.subtitle ~= b.subtitle then
        return a.subtitle < b.subtitle
      end
      return a.id < b.id
    end)

    local selected, reason, detail = rex.ui.pick{
      title = "Switch Session",
      placeholder = "Filter sessions",
      items = items,
    }
    if selected then
      session_navigation.select_session(ctx, selected, session_hosts[selected])
      record_visit(selected)
    elseif reason == "unsupported" then
      rex.client.queue("session.switch")
    elseif reason ~= "cancelled" then
      rex.log("warn", "Session picker: " .. (detail or reason))
    end
  end,
}
