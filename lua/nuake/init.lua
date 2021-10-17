local Nuake = {}
local Tools = require'nuake.tools'
local Win   = require'nuake.window'

Nuake.settings = {
  view = {
    floating = true,
    buffer = {
      position = 'bottom',
      rel_size = 0.4,
    },
    float = {
      position   = 'center',
      rel_height = 0.4,
      rel_width  = 0.8,
    },
  },
  close_if_last_standing = true,
  start_in_insert        = true,
  filetype               = 'nuake',
}


-------------------------------------------------------------------------------
--- Internal Nuake representation
local nuakes = {}

local function catch_nuake()
  return nuakes[vim.fn.tabpagenr()] or
    {
      win_id = -1,
      job_id = -1,
      bufnr  = -1,
      dir    = vim.fn.getcwd(),
    }
end

function Nuake.free(num)
  if nuakes[num] then
    nuakes[num] = nil
  end
end

function Nuake.hide()
  if nuakes[vim.fn.tabpagenr()] then
    nuakes[vim.fn.tabpagenr()].win_id = -1
  end
end

-------------------------------------------------------------------------------
--- Toggle the terminal

local function open(nuake)
  if Nuake.settings.view.floating then
    nuake.win_id = Win.float(nuake.bufnr, Nuake.settings.view.float)
  else
    vim.cmd('silent keepalt '..Win.split_geometry(nuake.win_id, Nuake.settings.view.buffer)..' split')
    nuake.win_id = vim.fn.win_getid()
  end

  -- Does the buffer already exist?
  if vim.fn.bufexists(nuake.bufnr) == 0 then
    -- Create a new empty buffer and set it as the current buf and win
    nuake.bufnr = vim.api.nvim_create_buf(false,false)
    vim.api.nvim_win_set_buf(nuake.win_id, nuake.bufnr)

    -- Open a terminal
    nuake.job_id = vim.fn.termopen(vim.o.shell, { detach = false })
    Win.buf_opts(nuake.bufnr, Nuake.settings.filetype)
    -- Autocommands
    local aucmds = {
      { "TermClose", string.format("<buffer=%d>", nuake.bufnr),
        string.format("lua require'nuake'.free(%d)", vim.fn.tabpagenr())
      },
      { "BufDelete", string.format("<buffer=%d>", nuake.bufnr),
        string.format("lua require'nuake'.free(%d)", vim.fn.tabpagenr())
      },
      { "WinClosed", string.format("<buffer=%d>", nuake.bufnr),
        "lua require'nuake'.hide()"
      },
      { "TabClosed", "*",
        string.format("bdelete! %d", nuake.bufnr)
      },
      { "TabClosed", "*",
        string.format("lua require'nuake'.free(%d)", vim.fn.tabpagenr())
      },
    }
    Tools.create_augroups({naukes_buf_aug = aucmds})
  else
    vim.cmd('buffer '..nuake.bufnr)
  end
  Win.win_opts(nuake.win_id, Nuake.settings.start_in_insert)

  -- Save it to the list of nuakes
  nuakes[vim.fn.tabpagenr()] = nuake
end

local function close(nuake)
  winnr = vim.fn.bufwinnr(nuake.bufnr)
  vim.cmd(winnr..'hide')
  nuake.win_id = -1
end

function Nuake.toggle()
  local nuake = catch_nuake()

  if Win.is_visible(nuake.win_id) then
    close(nuake)
  else
    open(nuake)
  end
end

-------------------------------------------------------------------------------
--- Execute a command
function Nuake.exec(job)
  local nuake = catch_nuake()
  if (not Win.is_visible(nuake.win_id)) then
    open(nuake)
  end
  vim.fn.chansend(nuake.job_id, job .. "\n")
  vim.cmd 'wincmd p'
end

-------------------------------------------------------------------------------
--- REPL

function Nuake.send_line(count)
  local nuake = catch_nuake()
  if (not Win.is_visible(nuake.win_id)) then
    open(nuake)
  end

  vim.fn.chansend(nuake.job_id,
    vim.fn.add(vim.fn.getline('.', vim.fn.line('.') + count - 1), "\n")
  )
  vim.cmd([[silent! call repeat#set("\<Plug>NuakeSendLine", ]] .. count .. ")")
end

function Nuake.send_buf()
  local nuake = catch_nuake()
  if (not Win.is_visible(nuake.win_id)) then
    open(nuake)
  end

  vim.fn.chansend(nuake.job_id,
    vim.fn.add(vim.fn.getline(1,'$'), "\n")
  )
  vim.cmd [[silent! call repeat#set("\<Plug>NuakeSendBuffer")]]
end

function Nuake.send_selection()
  local nuake = catch_nuake()
  if (not Win.is_visible(nuake.win_id)) then
    open(nuake)
  end

  local sl = vim.fn.getpos("'<")[2]
  local sc = vim.fn.getpos("'<")[3]
  local el = vim.fn.getpos("'>")[2]
  local ec = vim.fn.getpos("'>")[3]

  local sel = vim.fn.getline(sl, el)
  if #sel == 0 then
    return ''
  end

  sel[1]    = sel[1]:sub(sc,string.len(sel[1]))
  sel[#sel] = sel[#sel]:sub(1,ec - (vim.o.selection == 'inclusive' and 0 or 1))

  vim.fn.chansend(nuake.job_id,
    vim.fn.add(sel, "\n")
  )
end

function Nuake.send_paragraph(count)
  local nuake = catch_nuake()
  if (not Win.is_visible(nuake.win_id)) then
    open(nuake)
  end

  local pstart = vim.fn.search('^$', 'bnW')
  local pend

  pstart =  pstart == 0 and 1 or (pstart + 1)
  for _ = 1, count do
    pend = vim.fn.search('^$', 'nW') == 0 and
      vim.fn.line('$') or vim.fn.search('^$','nW')
    local _ = vim.fn.search('^.', 'W') == 0 and vim.fn.line('$') or vim.fn.search('^.','nW')
  end

  vim.fn.chansend(nuake.job_id,
    vim.fn.add(vim.fn.getline(pstart, pend), "\n")
  )
  vim.cmd([[silent! call repeat#set("\<Plug>NuakeSendParagraph", ]] .. count .. ")")
end

-------------------------------------------------------------------------------
--- Lua Plugin initialization
  -- Store user settings and initialize Vim autocommands.
  -- @param usr table of user settings
function Nuake.setup(usr)
  if usr then
    Nuake.settings = vim.tbl_deep_extend("force", Nuake.settings, usr)
  end

  -- Autocommands
  if Nuake.settings.close_if_last_standing then
    local aucmds = {
      { 'BufEnter', '*',
        "++nested", "lua require'nuake.window'.close_if_last_standing(' .. Nuake.settings.filetype .. ')"
      },
    }
    Tools.create_augroups({nuake_aug = aucmds})
  end
end

function Nuake.introspect()
  print(vim.inspect(nuakes))
end

return Nuake
