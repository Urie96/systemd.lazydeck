local M = {}

local cfg = {
  command = 'systemctl',
  journal_command = 'journalctl',
  keymap = {
    action = '<enter>',
    start = 'r',
    stop = 'x',
    restart = 'R',
    enable = 'e',
    disable = 'd',
    reload = 'l',
    follow = 'f',
    edit = 'E',
    show = 's',
    cat = 'c',
  },
  unit_types = {
    { name = 'service', icon = '󰒓' },
    { name = 'mount', icon = '󰋊' },
    { name = 'swap', icon = '󰓡' },
    { name = 'socket', icon = '󰖩' },
    { name = 'target', icon = '󰀘' },
    { name = 'device', icon = '󰟀' },
    { name = 'automount', icon = '󰉋' },
    { name = 'timer', icon = '󱎫' },
    { name = 'path', icon = '󰉖' },
    { name = 'slice', icon = '󰅩' },
    { name = 'scope', icon = '󰅲' },
  },
}

function M.setup(opt)
  cfg = deck.tbl_deep_extend('force', cfg, opt or {})
end

function M.get() return cfg end

return M
