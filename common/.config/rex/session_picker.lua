-- Rex exposes history navigation as a focus change. Track the sessions seen
-- by this picker in memory for the lifetime of the loaded config.
local visit_order = {}
local visit_count = 0

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

    local result, err = rex.call("session.list")
    if not result then
      error(err, 0)
    end

    if ctx.session_id then
      record_visit(ctx.session_id)
    end

    local items = {}
    for _, session in ipairs(result.sessions or {}) do
      if session.session_id ~= ctx.session_id then
        items[#items + 1] = {
          id = session.session_id,
          title = session.label ~= "" and session.label or session.session_id,
        }
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
      return a.id < b.id
    end)

    local selected, reason, detail = rex.ui.pick{
      title = "Switch Session",
      placeholder = "Filter sessions",
      items = items,
    }
    if selected then
      rex.client.queue("session.select", { session_id = selected })
      record_visit(selected)
    elseif reason == "unsupported" then
      rex.client.queue("session.switch")
    elseif reason ~= "cancelled" then
      rex.log("warn", "Session picker: " .. (detail or reason))
    end
  end,
}
