"=======================================================
"プラグイン設定 
"=======================================================

"vi互換オフ
if &compatible
  set nocompatible
endif

let dein_installation_path = '~/.vim/dein'
let dein_path = dein_installation_path . '/repos/github.com/Shougo/dein.vim'
let plugin_base_path = '~/.vim/dein'

execute 'set runtimepath+=' . dein_path

if dein#load_state(plugin_base_path)
  call dein#begin(plugin_base_path)

  call dein#add('Shougo/dein.vim')

  call dein#add('Shougo/unite.vim')
  call dein#add('Shougo/vimfiler')
  call dein#add('Shougo/neocomplcache')
  call dein#add('thinca/vim-quickrun')
  call dein#add('tyru/open-browser.vim')
  call dein#add('kannokanno/previm')
  call dein#add('Shougo/neosnippet')
  call dein#add('Shougo/neosnippet-snippets')
  call dein#add('mattn/emmet-vim')
  call dein#add('tpope/vim-rails')
  call dein#add('w0rp/ale')

  call dein#end()
  call dein#save_state()
endif

filetype plugin indent on

"=======================================================
"matchit設定
"=======================================================
source $VIMRUNTIME/macros/matchit.vim


runtime! config/init/*.vim
runtime! config/plugins/*.vim
