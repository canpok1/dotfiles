"vi互換オフ
if &compatible
  set nocompatible
endif

filetype plugin indent on

"=======================================================
"matchit設定
"=======================================================
source $VIMRUNTIME/macros/matchit.vim


runtime! config/init/*.vim
