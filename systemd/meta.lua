local action = require 'systemd.action'

local M = {}

local function add_keymap(targets, key, callback, desc)
  if not key or key == '' then return end
  for _, target in ipairs(targets) do
    target[key] = { callback = callback, desc = desc }
  end
end

local metas = {
  scope = {
    __index = {
      keymap = {},
      preview = function(entry, cb)
        cb(action.scope_preview(entry))
      end,
    },
  },
  type = {
    __index = {
      keymap = {},
      preview = function(entry, cb)
        cb(action.type_preview(entry))
      end,
    },
  },
  unit = {
    __index = {
      keymap = {},
      preview = function(entry, cb)
        action.unit_preview(entry, cb)
      end,
    },
  },
  info = {
    __index = {
      keymap = {},
      preview = function(entry, cb)
        cb(action.info_preview(entry))
      end,
    },
  },
}

function M.setup(cfg)
  local keymap = (cfg or {}).keymap or {}
  local unit_map = metas.unit.__index.keymap

  for key, _ in pairs(unit_map) do
    unit_map[key] = nil
  end

  add_keymap({ unit_map }, keymap.action, action.select_action, 'unit actions')
  add_keymap({ unit_map }, keymap.start, action.start, 'start unit')
  add_keymap({ unit_map }, keymap.stop, action.stop, 'stop unit')
  add_keymap({ unit_map }, keymap.restart, action.restart, 'restart unit')
  add_keymap({ unit_map }, keymap.enable, action.enable, 'enable unit')
  add_keymap({ unit_map }, keymap.disable, action.disable, 'disable unit')
  add_keymap({ unit_map }, keymap.reload, action.reload, 'reload unit')
  add_keymap({ unit_map }, keymap.follow, action.follow, 'follow logs')
  add_keymap({ unit_map }, keymap.edit, action.edit, 'edit unit')
  add_keymap({ unit_map }, keymap.show, action.show, 'show unit')
  add_keymap({ unit_map }, keymap.cat, action.cat, 'cat unit')
end

function M.attach(entries)
  for i, entry in ipairs(entries or {}) do
    local mt = metas[entry.kind]
    if mt then entries[i] = setmetatable(entry, mt) end
  end
  return entries
end

return M
