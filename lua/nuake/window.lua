local Win = {}

function Win.buf_opts(bufnr, filetype)
  vim.bo[bufnr].filetype  = filetype
  vim.bo[bufnr].buflisted = false
  vim.bo[bufnr].swapfile  = false
  vim.bo[bufnr].modified  = false
end

function Win.win_opts(winid, to_start_insert)
  vim.wo[winid].winfixheight   = true
  vim.wo[winid].winfixwidth    = true
  vim.wo[winid].spell          = false
  vim.wo[winid].foldenable     = false
  vim.wo[winid].number         = false
  vim.wo[winid].relativenumber = false
  vim.wo[winid].signcolumn     = 'no'
  if to_start_insert then
    vim.cmd("startinsert!")
  end
end

function Win.is_visible(winid)
  return winid ~= -1
end

function Win.float(bufnr, settings)
  local width  = vim.opt.columns:get()
  local height = vim.opt.lines:get()

  local winH = math.ceil(height * settings.rel_height)
  local winW = math.ceil(width * settings.rel_width)

  local columns = math.ceil((width - winW)/2)
  local rows
  if settings.position == 'center' then
    rows = math.ceil((height - winH)/2 - 1)
  elseif settings.position == 'bottom' then
    rows = height
  elseif settings.position == 'top' then
    rows = 0
  end

  local opts = {
    relative = 'editor',
    row      = rows,
    col      = columns,
    width    = winW,
    height   = winH,
    style    = 'minimal',
    border   = 'rounded',
  }

  return vim.api.nvim_open_win(bufnr, true, opts)
end


function Win.split_geometry(winid, settings)
  local mode, size

  if settings.pos == 'bottom' then
    mode = 'botright '
    size = math.floor(settings.rel_size * (vim.o.lines - 2))
  elseif settings.pos == 'top' then
    mode = 'topleft '
    size = math.floor(settings.rel_size * (vim.o.lines - 2))
  elseif settings.pos == 'right' then
    mode = 'botright vertical '
    size = math.floor(settings.rel_size * vim.o.columns)
  elseif settings.pos == 'left' then
    mode = 'topleft vertical '
    size = math.floor(settings.rel_size * vim.o.columns)
  else
    print(string.format('%s is not a valid option for nuake.buffer.pos', settings.pos))
    mode = Win.is_visible(winid) and '' or 'botright '
    size = math.floor(0.25 * (vim.o.lines - 2))
  end

  return mode .. size
end

function Win.close_if_last_standing(filetype)
  local buf = vim.api.nvim_get_current_buf()
  if vim.fn.winnr('$') == 1 and vim.bo[buf].filetype == filetype then
    if vim.fn.tabpagenr('$') == 1 then
      vim.cmd 'bdelete!'
      vim.cmd 'quit'
    else
      vim.cmd 'bdelete!'
    end
  end
end

return Win
