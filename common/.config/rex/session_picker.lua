-- Rex keeps sessions attached after it switches away from them, so the app's
-- attachment list cannot tell us its previous session.
local pair_by_client = {}

-- Track visits made by these actions for the lifetime of the loaded config.
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

local function run_rex(argv)
  local command = { "rex", "--autostart=false", "--timeout", "3s" }
  for _, arg in ipairs(argv) do
    command[#command + 1] = arg
  end
  local options = { timeout = 5, env = { REX_SERVER = false } }
  local result, err = rex.exec(command, options)
  if not result and os.getenv("HOME") then
    command[1] = os.getenv("HOME") .. "/Library/Application Support/com.superlogical.rex/"
      .. "RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
    result, err = rex.exec(command, options)
  end
  if not result then
    return nil, err
  end
  if not result.ok then
    return nil, result.stderr
  end
  return result.stdout
end

local function home_call(method, args)
  -- From a remote session, rex.call follows that session's host.
  local argv = { "api", "call", method }
  if args then
    argv[#argv + 1] = assert(rex.json.encode(args))
  end
  local output, err = run_rex(argv)
  if not output then
    return nil, err
  end
  return rex.json.decode(output)
end

local function select_session(ctx, session_id, server)
  local args = { session_id = session_id }
  if not server and not ctx.server then
    rex.client.queue("session.select", args)
    return
  end

  -- session.select resolves IDs on the connection that delivers the action.
  -- Use a separate CLI connection so the app can answer the request while
  -- it is waiting for this picker action to finish.
  local call_home = ctx.server and home_call or rex.call
  local client = assert(call_home("client.inspect", { client_id = ctx.client_id })).client
  local label = client.info.label
  if not label or label == "" then
    error("The Rex app needs a client label to switch hosts.", 0)
  end
  local argv = { "-C", label, "do", "session.select", "session_id=" .. session_id }
  if server then
    table.insert(argv, 1, server)
    table.insert(argv, 1, "-S")
  end
  assert(run_rex(argv))
end

local pick_alternate = {
  name = "pick_alternate_session",
  title = "Choose Alternate Session",
  run = function(ctx)
    if not rex.ui then
      rex.client.queue("session.switch")
      return
    end

    if ctx.session_id then
      record_visit(ctx.session_id)
    end

    local icon_by_host = {}
    local call_home = ctx.server and home_call or rex.call
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
      add_sessions(nil, home_call("session.list"))
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
      title = "Choose Alternate Session",
      placeholder = "Filter sessions",
      items = items,
    }
    if selected then
      select_session(ctx, selected, session_hosts[selected])
      if ctx.client_id and ctx.session_id then
        pair_by_client[ctx.client_id] = {
          [ctx.session_id] = { id = selected, server = session_hosts[selected] },
          [selected] = { id = ctx.session_id, server = ctx.server },
        }
      end
      record_visit(selected)
    elseif reason == "unsupported" then
      rex.client.queue("session.switch")
    elseif reason ~= "cancelled" then
      rex.log("warn", "Session picker: " .. (detail or reason))
    end
  end,
}
rex.action(pick_alternate)

rex.action{
  name = "toggle_session_pair",
  title = "Toggle Between Sessions",
  run = function(ctx)
    local pair = pair_by_client[ctx.client_id]
    local alternate = pair and pair[ctx.session_id]
    if not alternate then
      pick_alternate.run(ctx)
      return
    end

    select_session(ctx, alternate.id, alternate.server)
    record_visit(alternate.id)
  end,
}
