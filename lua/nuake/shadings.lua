-----------------------------------------------------------------------------
-- Define and apply highlightings groups for the groundhogs
-- Shadings capabilities for the groundhogs NeoVim plugin
-- Author: Marco Cantoro
-----------------------------------------------------------------------------

--- Transform an HEX color string into an RGB color and
  -- decompose it into its three components
local function to_rgb(color)
  local r = tonumber(string.sub(color, 2, 3), 16)
  local g = tonumber(string.sub(color, 4, 5), 16)
  local b = tonumber(string.sub(color, 6),    16)
  return r, g, b
end

--- Programattically shaden/lighten an HEX color and blend the colors
  -- @param color string HEX color
  -- @param percent number percentage value to which the color is lighten
local function shade(color, percent)
  local r, g, b = to_rgb(color)

  if not r or not g or not b then
    return 'NONE'
  end

  r = math.floor(tonumber(r * (1 + percent / 100)))
  g = math.floor(tonumber(g * (1 + percent / 100)))
  b = math.floor(tonumber(b * (1 + percent / 100)))

  r = r < 255 and r or 255
  g = g < 255 and g or 255
  b = b < 255 and b or 255

  r = string.format("%x", r)
  g = string.format("%x", g)
  b = string.format("%x", b)

  local rr = string.len(r) == 1 and "0" .. r or r
  local gg = string.len(g) == 1 and "0" .. g or g
  local bb = string.len(b) == 1 and "0" .. b or b

  return "#" .. rr .. gg .. bb
end

local M = {}

--- This function is responsible to define the highlighting groups,
  -- both the name and the color and font characteristics
  -- Positive value will lighten the terminal colors and vice versa.
  -- @param amount (number) percentage to which lighten the groundhog
function M.set_highlights(amount)
  local bg_color  = vim.fn.synIDattr(vim.fn.hlID('Normal'), 'bg')
  local shaded_bg = shade(bg_color, amount)

  vim.cmd('highlight ShadedPanel                              guibg=' .. shaded_bg)
  vim.cmd('highlight ShadedStatusline                gui=NONE guibg=' .. shaded_bg)
  vim.cmd('highlight ShadedStatuslineNC cterm=italic gui=NONE guibg=' .. shaded_bg)
end

--- Calls winhighlight to apply the defined window-local
  -- highlightings for the groundhog terminals
  -- to the built-in Vim highlightings
function M.shades()
  local highlights = {
    "Normal:ShadedPanel",
    "VertSplit:ShadedPanel",
    "StatusLine:ShadedStatusline",
    "StatusLineNC:ShadedStatuslineNC",
    "SignColumn:ShadedPanel"
  }
  vim.cmd("setlocal winhighlight=" .. table.concat(highlights, ","))
end

return M
