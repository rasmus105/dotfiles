local session_navigation = {}

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

function session_navigation.home_call(method, args)
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

function session_navigation.select_session(ctx, session_id, server)
  local args = { session_id = session_id }
  if not server and not ctx.server then
    rex.client.queue("session.select", args)
    return
  end

  -- session.select resolves IDs on the connection that delivers the action.
  -- Use a separate CLI connection so the app can answer the request while
  -- it is waiting for this picker action to finish.
  local call_home = ctx.server and session_navigation.home_call or rex.call
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

return session_navigation
