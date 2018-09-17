highlight ALEWarning cterm=underline ctermfg=NONE ctermbg=NONE
highlight ALEError cterm=underline ctermfg=NONE ctermbg=NONE

let g:ale_linters = {
      \ 'ruby': ['rubocop', 'reek', 'rails_best_practices'],
      \ 'javascript': ['eslint'],
      \ }

let g:ale_statusline_format = ['[E:%d]', '[W:%d]', '']

nmap <silent> <C-k> <Plug>(ale_previous)
nmap <silent> <C-j> <Plug>(ale_next)
