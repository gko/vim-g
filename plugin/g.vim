" vim-g - The handy Google lookup for Vim
" Maintainer:   Szymon Wrozynski
" Version:    0.0.6
"
" Installation:
" Place in ~/.vim/plugin/g.vim or in case of Pathogen:
"
"   cd ~/.vim/bundle
"   git clone https://github.com/szw/vim-g.git
"
" License:
" Copyright (c) 2012-2014 Szymon Wrozynski and Contributors. Distributed under the same terms as Vim itself.
" See :help license
"
" Usage:
" https://github.com/szw/vim-g/blob/master/README.md
"

if exists("g:loaded_vim_g") || &cp || v:version < 700
  finish
endif

let g:loaded_vim_g = 1

if !exists("g:vim_g_open_command")
  if has("win32")
    let g:vim_g_open_command = "start"
  elseif substitute(system('uname'), "\n", "", "") == 'Darwin'
    let g:vim_g_open_command = "open"
  else
    if executable("xdg-open")
      let g:vim_g_open_command = "xdg-open"
    elseif executable("gio")
      let g:vim_g_open_command = "gio open"
    else
      let g:vim_g_open_command = ""
    endif
  endif
endif

if !exists("g:vim_g_python_command")
  let g:vim_g_python_command = "python3"
endif

if !exists("g:vim_g_query_url")
  let g:vim_g_query_url = "https://google.com/search?q="
endif

if !exists("g:vim_g_command")
  let g:vim_g_command = "Google"
endif

if !exists("g:vim_g_f_command")
  let g:vim_g_f_command = g:vim_g_command . "f"
endif

execute "command! -nargs=* -range ". g:vim_g_command  ." :call s:goo('', <f-args>)"
execute "command! -nargs=* -range ". g:vim_g_f_command ." :call s:goo(&ft, <f-args>)"

fun! s:goo(ft, ...)
  if empty(g:vim_g_open_command)
    echohl WarningMsg | echo "vim-g: No opener found. Set g:vim_g_open_command manually." | echohl None
    return
  endif

  let sel = ''
  let m_start = getpos("'<")
  let m_end = getpos("'>")
  let cur = getpos('.')
  let mode = visualmode()

  let is_fresh = (mode ==# 'v' && (cur == m_start || cur == m_end)) ||
        \ (mode ==# 'V' && (cur[1] == m_start[1] || cur[1] == m_end[1])) ||
        \ (mode ==# "\<C-V>" && (cur[1] == m_start[1] || cur[1] == m_end[1]))

  if is_fresh
    let lines = getline("'<", "'>")
    if !empty(lines)
      if mode ==# 'v'
        let lines[-1] = lines[-1][:m_end[2] - 1]
        let lines[0] = lines[0][m_start[2] - 1:]
      elseif mode ==# "\<C-V>"
        let c1 = m_start[2] - 1
        let c2 = m_end[2] - 1
        let s_col = c1 < c2 ? c1 : c2
        let e_col = c1 < c2 ? c2 : c1
        for i in range(len(lines))
          let lines[i] = lines[i][s_col : e_col]
        endfor
      endif
      let sel = join(lines, ' ')
    endif
  endif

  if a:0 == 0
    let words = [a:ft, empty(sel) ? expand("<cword>") : sel]
  else
    let query = join(a:000, " ")
    let words = [a:ft, query, (empty(sel) ? '' : sel)]
    call filter(words, 'len(v:val)')
  endif

  " Clean the query and REMOVE manual quote-escaping.
  " shellescape() and sys.argv will handle the quotes safely.
  let query = substitute(join(words, " "), '^\s*\(.\{-}\)\s*$', '\1', '')

  if has('win32')
    silent! execute "! " . g:vim_g_open_command . " \"\" \"" . g:vim_g_query_url  . query . "\""
  else
    " escape "!"
    let safe_query = shellescape(query, 1)
    silent! execute "! goo_query=$(" . g:vim_g_python_command .
          \" -c 'import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))' " . safe_query . ") && " .
          \g:vim_g_open_command . ' "' . g:vim_g_query_url . "$goo_query" . '" > /dev/null 2>&1 &'
  endif
  redraw!
endfun
