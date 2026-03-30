local config = require 'systemd.config'
local meta = require 'systemd.meta'

local M = {}

local function span(text, color)
  local s = lc.style.span(tostring(text or ''))
  if color and color ~= '' then s = s:fg(color) end
  return s
end

local function line(parts) return lc.style.line(parts) end

local function scope_entry(scope)
  local icon = scope == 'system' and '󰍹' or '󰀄'
  local color = scope == 'system' and 'cyan' or 'green'
  local label = scope == 'system' and 'System' or 'User'
  return {
    key = scope,
    kind = 'scope',
    scope = scope,
    display = line {
      span(icon, color),
      span(' ', 'darkgray'),
      span(label, 'white'),
    },
  }
end

local function type_entry(scope, unit_type)
  local label = unit_type.name:gsub('^%l', string.upper)
  return {
    key = unit_type.name,
    kind = 'type',
    scope = scope,
    unit_type = unit_type.name,
    icon = unit_type.icon,
    display = line {
      span(unit_type.icon .. ' ' .. label, 'yellow'),
    },
  }
end

local function unit_state_color(load_state, active_state)
  if load_state == 'not-found' then return 'yellow' end
  if active_state == 'active' then return 'green' end
  if active_state == 'failed' then return 'red' end
  if active_state == 'activating' or active_state == 'deactivating' then return 'yellow' end
  return 'white'
end

local function build_unit_entries(scope, unit_type, data)
  local entries = {}
  for _, unit in ipairs(data or {}) do
    local unit_name = unit.unit
    local load_state = unit.load or ''
    local active_state = unit.active or ''
    local sub_state = unit.sub or ''
    local description = unit.description or ''

    table.insert(entries, {
      key = unit_name,
      kind = 'unit',
      unit = unit_name,
      load = load_state,
      active = active_state,
      sub = sub_state,
      description = description,
      scope = scope,
      type = unit_type,
      display = line {
        span(unit_name, unit_state_color(load_state, active_state)),
        span(description ~= '' and ('  ' .. description) or '', 'darkgray'),
      },
    })
  end
  return meta.attach(entries)
end

local function list_units(path, cb)
  local scope = path[2]
  local unit_type = path[3]
  local cmd = {
    config.get().command,
    '--' .. scope,
    'list-units',
    '--type=' .. unit_type,
    '--all',
    '--output=json',
    '--no-pager',
  }

  lc.system(cmd, function(out)
    if out.code ~= 0 then
      lc.log('error', 'Failed to list units: {}', out.stderr or 'Unknown error')
      cb(meta.attach {
        {
          key = 'error',
          kind = 'info',
          title = 'systemd',
          message = 'Failed to list units',
          detail = out.stderr or 'Unknown error',
          color = 'red',
        },
      })
      return
    end

    local success, data = pcall(lc.json.decode, out.stdout)
    if not success or type(data) ~= 'table' then
      lc.log('error', 'Failed to parse JSON output: {}', data or 'Unknown error')
      cb(meta.attach {
        {
          key = 'error',
          kind = 'info',
          title = 'systemd',
          message = 'Failed to parse units JSON',
          detail = tostring(data or 'Unknown error'),
          color = 'red',
        },
      })
      return
    end

    cb(build_unit_entries(scope, unit_type, data))
  end)
end

function M.setup(opt)
  config.setup(opt or {})
  meta.setup(config.get())
end

function M.list(path, cb)
  if #path == 1 then
    cb(meta.attach {
      scope_entry('system'),
      scope_entry('user'),
    })
    return
  end

  if #path == 2 then
    local entries = {}
    for _, unit_type in ipairs(config.get().unit_types or {}) do
      table.insert(entries, type_entry(path[2], unit_type))
    end
    cb(meta.attach(entries))
    return
  end

  if #path == 3 then
    list_units(path, cb)
    return
  end

  cb(meta.attach {})
end

return M
