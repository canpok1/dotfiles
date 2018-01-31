"=======================================================
"自作コマンド
"=======================================================
"画面端での折り返しの切替
command! ToggleWrap :set invwrap
"vimrc,gvimrcの編集
command! VimrcEdit :tabe $HOME/dotfiles/_vimrc
command! GvimrcEdit :tabe $HOME/dotfiles/_gvimrc
"vimrc,gvimrcの再読み込み
command! VimrcReload :source $HOME/dotfiles/_vimrc
command! GvimrcReload :source $HOME/dotfiles/_gvimrc
"よくないログの検索
command! ListupBadLog :g/ FATAL \| ERROR \| WARN 
command! ListupBadLogQF :vim/ FATAL \| ERROR \| WARN /%|cw
"文字コード設定
command! SetSJIS :set fenc=cp932
command! SetJIS :set fenc=iso-2022-jp
command! SetEUC :set fenc=euc-jp
command! SetUTF8 :set fenc=utf-8
command! SetUTF8BOM :set fenc=utf-8 bomb
"文字コード指定で開きなおす
command! ReloadSJIS :e ++enc=cp932
command! ReloadJIS :e ++enc=iso-2022-jp
command! ReloadEUC :e ++enc=euc-jp
command! ReloadUTF8 :e ++enc=utf-8
command! ReloadUTF8BOM :e ++enc=utf-8 bomb
"改行コード設定
command! SetCRLF :set ff=dos
command! SetCR :set ff=mac
command! SetLF :set ff=unix
"改行コード指定で開きなおす
command! ReloadCRLF :e ++ff=dos
command! ReloadCR :e ++ff=mac
command! ReloadLF :e ++ff=unix

function! OpenNewTab()
    if winner('$')!=1 || tabpagenr('$')!=1
        execute ":q"
        let l:f=expand("%:p")
        execute ":tabnew" .l:f
    endif
endfunction

