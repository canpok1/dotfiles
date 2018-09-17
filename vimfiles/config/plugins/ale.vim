highlight ALEWarning cterm=underline ctermfg=NONE ctermbg=NONE
highlight ALEError cterm=underline ctermfg=NONE ctermbg=NONE

let g:ale_linters = {
      \ 'ruby': ['rubocop'],
      \ 'javascript': ['eslint'],
      \ }

let g:ale_statusline_format = ['[E:%d]', '[W:%d]', '']
