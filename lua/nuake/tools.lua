local Tools = {}

function Tools.create_augroups(Augroups)
  for name, def in pairs(Augroups) do
    vim.cmd('augroup ' .. name)
    vim.cmd 'autocmd!'
    for _, args in pairs(def) do
      local autocmd = table.concat(vim.tbl_flatten { 'autocmd', args }, ' ')
      vim.cmd(autocmd)
    end
    vim.cmd 'augroup END'
  end
end

return Tools
