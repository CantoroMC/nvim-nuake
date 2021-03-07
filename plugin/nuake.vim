" plugin/nuake.vim
" Author:        Marco Cantoro
" Description:   A Quake-style terminal panel written in Lua
" Last Modified: Mar 05, 21

if exists('g:loaded_nuake')
  finish
endif
let g:loaded_nuake = 1


" Main:
command! -nargs=* -complete=shellcmd
      \ NuakeExec          lua require'nuake'.exec(<q-args>)
command! -nargs=0
      \ NuakeToggle        lua require'nuake'.toggle()

nnoremap <silent> <Plug>NuakeToggle :<C-U>NuakeToggle<CR>
if !hasmapto('<Plug>NuakeToggle', 'n') && maparg('<C-\>', 'n') ==# ''
  nmap <C-\> <Plug>NuakeToggle
end

" REPL:
command! -nargs=0 -count=1
      \ NuakeSendLine      lua require'nuake'.send_line(<count>)
command! -nargs=0 -count=1
      \ NuakeSendParagraph lua require'nuake'.send_paragraph(<count>)
command! -nargs=0
      \ NuakeSendBuffer    lua require'nuake'.send_buf()
command! -nargs=0 -range
      \ NuakeSendSelection lua require'nuake'.send_selection()

nnoremap <silent> <Plug>NuakeSendLine      :<C-U>execute v:count1.'NuakeSendLine'<CR>
nnoremap <silent> <Plug>NuakeSendParagraph :<C-U>execute v:count1.'NuakeSendParagraph'<CR>
nnoremap <silent> <Plug>NuakeSendBuffer    :<C-U>NuakeSendBuffer<CR>
xnoremap <silent> <Plug>NuakeSendSelection :<C-U>NuakeSendSelection<CR>

if !hasmapto('<Plug>NuakeSendLine', 'n') && maparg('<C-\><C-c><C-l>', 'n') ==# ''
  nmap <C-\><C-c><C-l> <Plug>NuakeSendLine
end
if !hasmapto('<Plug>NuakeSendParagraph', 'n') && maparg('<C-\><C-c><C-p>', 'n') ==# ''
  nmap <C-\><C-c><C-p> <Plug>NuakeSendParagraph
end
if !hasmapto('<Plug>NuakeSendBuffer', 'n') && maparg('<C-\><C-c><C-b>', 'n') ==# ''
  nmap <C-\><C-c><C-b> <Plug>NuakeSendBuffer
end
if !hasmapto('<Plug>NuakeSendSelection', 'x') && maparg('<C-\><C-c>', 'x') ==# ''
  xmap <C-\><C-c> <Plug>NuakeSendSelection
end
