-------------------------------------------------------------------------------
--- Variables
local fn  = vim.fn
local cmd = vim.cmd
local api = vim.api

local shadings = require'nuake.shadings'

local plug_settings = {
  pos                    = 'right',
  rel_size               = 0.40,
  close_if_last_standing = true,
  shade_terminals        = true,
  start_in_insert        = false,
}

local M = {}

-------------------------------------------------------------------------------
--- Internal Nuake representation
local nuake_ft = 'nuake'
local nuakes = {}

local function initialize()
  return {
    win_id = -1,
    job_id = -1,
    bufnr  = -1,
    dir    = fn.getcwd(),
  }
end

local function catch_nuake()
  return nuakes[fn.tabpagenr()] or initialize()
end

-------------------------------------------------------------------------------
--- Nuake options and look
local function isVisible(win_id)
  return win_id ~= -1
end

local function set_buf_opts(nuake)
  local bufnr = nuake.bufnr
  -- bufhidden or create_buf
  vim.bo[bufnr].filetype        = nuake_ft
  vim.bo[bufnr].buflisted       = false
  vim.bo[bufnr].swapfile        = false
  vim.bo[bufnr].modified        = false

  if plug_settings.shade_terminals then
    shadings.set_highlights(-30)
    shadings.shades()
  end
end

local function set_win_opts(nuake)
  local win_id = nuake.win_id
  vim.wo[win_id].winfixheight   = true
  vim.wo[win_id].winfixwidth    = true
  vim.wo[win_id].spell          = false
  vim.wo[win_id].foldenable     = false
  vim.wo[win_id].number         = false
  vim.wo[win_id].relativenumber = false
  vim.wo[win_id].signcolumn     = 'no'
  if plug_settings.start_in_insert then
    cmd("startinsert!")
  end
end

local function geometry(win_id)
  local mode, size

  if plug_settings.pos == 'bottom' then
    mode = isVisible(win_id) and '' or 'botright '
    size = math.floor(plug_settings.rel_size * (vim.o.lines - 2))
  elseif plug_settings.pos == 'top' then
    mode = isVisible(win_id) and '' or 'topleft '
    size = math.floor(plug_settings.rel_size * (vim.o.lines - 2))
  elseif plug_settings.pos == 'right' then
    mode = isVisible(win_id) and '' or 'botright vertical '
    size = math.floor(plug_settings.rel_size * vim.o.columns)
  elseif plug_settings.pos == 'left' then
    mode = isVisible(win_id) and '' or 'topleft vertical '
    size = math.floor(plug_settings.rel_size * vim.o.columns)
  else
    print(string.format('%s is not a valid option for nuake.pos', plug_settings.pos))
    mode = isVisible(win_id) and '' or 'botright '
    size = math.floor(0.25 * (vim.o.lines - 2))
  end

  return mode .. size
end

-------------------------------------------------------------------------------
--- Functions for Autocommands
local function create_augs(augs_tbl)
  for name, def in pairs(augs_tbl) do
    cmd('augroup ' .. name)
    cmd 'autocmd!'
    for _, args in pairs(def) do
      local autocmd = table.concat(vim.tbl_flatten { 'autocmd', args }, ' ')
      cmd(autocmd)
    end
    cmd 'augroup END'
  end
end

function M.close_if_last_standing()
  local buf = api.nvim_get_current_buf()
  if fn.winnr('$') == 1 and vim.bo[buf].filetype == nuake_ft then
    if fn.tabpagenr('$') == 1 then
      cmd 'bdelete!'
      cmd 'quit'
    else
      cmd 'bdelete!'
    end
  end
end

function M.free(num)
  if nuakes[num] then
    nuakes[num] = nil
  end
end

function M.hide()
  if nuakes[fn.tabpagenr()] then
    nuakes[fn.tabpagenr()].win_id = -1
  end
end

function M.vim_resized()
  nuake = nuakes[fn.tabpagenr()]
  winnr = fn.bufwinnr(nuake.bufnr)
  if isVisible(nuake.win_id) then
    cmd(winnr .. 'resize ' .. geometry(nuake.win_id))
    cmd 'redraw'
  end
end

-------------------------------------------------------------------------------
--- Toggle the terminal
local function open(nuake)
  cmd('silent keepalt '..geometry(nuake.win_id)..' split')
  nuake.win_id = fn.win_getid()
  -- Does the buffer already exist?
  if fn.bufexists(nuake.bufnr) == 0 then
    -- Create a new empty buffer and set it as the current buf and win
    nuake.bufnr = api.nvim_create_buf(false,false)
    api.nvim_set_current_buf(nuake.bufnr)
    api.nvim_win_set_buf(nuake.win_id, nuake.bufnr)
    -- Open a terminal
    nuake.job_id = fn.termopen(vim.o.shell, { detach = false })
    set_buf_opts(nuake)
    -- Autocommands
    local aucmds = {
      { "TermClose", string.format("<buffer=%d>", nuake.bufnr),
        string.format("lua require'nuake'.free(%d)", fn.tabpagenr())
      },
      { "BufDelete", string.format("<buffer=%d>", nuake.bufnr),
        string.format("lua require'nuake'.free(%d)", fn.tabpagenr())
      },
      { "WinClosed", string.format("<buffer=%d>", nuake.bufnr),
        "lua require'nuake'.hide()"
      },
      { "TabClosed", "*",
        string.format("bdelete! %d", nuake.bufnr)
      },
      { "TabClosed", "*",
        string.format("lua require'nuake'.free(%d)", fn.tabpagenr())
      },
    }
    create_augs({naukes_buf_aug = aucmds})
  else
    cmd('buffer '..nuake.bufnr)
  end
    set_win_opts(nuake)

    -- Save it to the list of nuakes
    nuakes[fn.tabpagenr()] = nuake
end

local function close(nuake)
  winnr = fn.bufwinnr(nuake.bufnr)
  cmd(winnr..'hide')
  nuake.win_id = -1
end

function M.toggle()
  local nuake = catch_nuake()

  if isVisible(nuake.win_id) then
    close(nuake)
  else
    open(nuake)
  end
end

-------------------------------------------------------------------------------
--- Execute a command
function M.exec(job)
  local nuake = catch_nuake()
  if (not isVisible(nuake.win_id)) then
    open(nuake)
  end
  fn.chansend(nuake.job_id, job .. "\n")
  cmd 'wincmd p'
end

-------------------------------------------------------------------------------
--- REPL

function M.send_line(count)
  local nuake = catch_nuake()
  if (not isVisible(nuake.win_id)) then
    open(nuake)
  end

  fn.chansend(nuake.job_id,
    fn.add(fn.getline('.', fn.line('.') + count - 1), "\n")
  )
  cmd([[silent! call repeat#set("\<Plug>NuakeSendLine", ]] .. count .. ")")
end

function M.send_buf()
  local nuake = catch_nuake()
  if (not isVisible(nuake.win_id)) then
    open(nuake)
  end

  fn.chansend(nuake.job_id,
    fn.add(fn.getline(1,'$'), "\n")
  )
  cmd [[silent! call repeat#set("\<Plug>NuakeSendBuffer")]]
end

function M.send_selection()
  local nuake = catch_nuake()
  if (not isVisible(nuake.win_id)) then
    open(nuake)
  end

  local sl = fn.getpos("'<")[2]
  local sc = fn.getpos("'<")[3]
  local el = fn.getpos("'>")[2]
  local ec = fn.getpos("'>")[3]

  local sel = fn.getline(sl, el)
  if #sel == 0 then
    return ''
  end

  sel[1]    = sel[1]:sub(sc,string.len(sel[1]))
  sel[#sel] = sel[#sel]:sub(1,ec - (vim.o.selection == 'inclusive' and 0 or 1))

  fn.chansend(nuake.job_id,
    fn.add(sel, "\n")
  )
end

function M.send_paragraph(count)
  local nuake = catch_nuake()
  if (not isVisible(nuake.win_id)) then
    open(nuake)
  end

  local pstart = fn.search('^$', 'bnW')
  local pend

  pstart =  pstart == 0 and 1 or (pstart + 1)
  for _ = 1, count do
    pend = vim.fn.search('^$', 'nW') == 0 and
      fn.line('$') or fn.search('^$','nW')
    local _ = vim.fn.search('^.', 'W') == 0 and fn.line('$') or fn.search('^.','nW')
  end

  fn.chansend(nuake.job_id,
    fn.add(fn.getline(pstart, pend), "\n")
  )
  cmd([[silent! call repeat#set("\<Plug>NuakeSendParagraph", ]] .. count .. ")")
end

-------------------------------------------------------------------------------
--- Lua Plugin initialization
  -- Store user settings and initialize Vim autocommands.
  -- @param user_settings table of user settings
function M.setup(user_settings)
  if user_settings then
    plug_settings = vim.tbl_deep_extend("force", plug_settings, user_settings)
  end

  -- Autocommands
  if plug_settings.close_if_last_standing then
    local aucmds = {
      { 'BufEnter', '*',
        "++nested", "lua require'nuake'.close_if_last_standing()"
      },
      { 'VimResized', '*',
        "lua require'nuake'.vim_resized()"
      },
    }
    create_augs({nuake_aug = aucmds})
  end
end

function M.introspect()
  print(vim.inspect(nuakes))
end

return M
