"=======================================================
"プラグイン設定 {{{
"=======================================================

"vi互換オフ
set nocompatible
"ファイルタイプを一時的にオフ
filetype off

"neobundle初期化"
set runtimepath+=~/.vim/bundle/neobundle.vim/
call neobundle#begin(expand('~/.vim/bundle/'))
NeoBundleFetch 'Shougo/neobundle.vim'

"プラグインのリポジトリ
NeoBundle 'Shougo/unite.vim'
NeoBundle 'Shougo/vimfiler'
NeoBundle 'Shougo/neocomplcache'
NeoBundle 'thinca/vim-quickrun'
NeoBundle 'tyru/open-browser.vim'
NeoBundle 'kannokanno/previm'
NeoBundle 'Shougo/neosnippet'
NeoBundle 'Shougo/neosnippet-snippets'
NeoBundle 'mattn/emmet-vim'

call neobundle#end()

NeoBundleCheck

"ファイル形式検出、プラグイン、インデントをオン
filetype plugin indent on

"}}}
"=======================================================

"=======================================================
"ファイルタイプ設定"{{{
"=======================================================
au BufRead,BufNewFile *.gradle set filetype=groovy
au BufRead,BufNewFile *.{md,mdwn,mkd,mkdn} set filetype=markdown
"}}}
"=======================================================

"=======================================================
"基本設定 {{{
"=======================================================
if has("win32") || has("win64")
    "スワップファイルの出力先設定
    set directory=~/vimfiles/tmp
    "viminfoの出力先設定
    set viminfo+=n~/vimfiles/tmp/viminfo.txt
else
    "スワップファイルの出力先設定
    set directory=~/.vim/tmp
    "viminfoの出力先設定
    set viminfo+=n~/.vim/tmp/viminfo.txt
endif

"チルダファイルの出力先設定
set nobackup

"行表示
set number

"クリップボードを利用
set clipboard=unnamed

"入力されているテキストの最大幅 [0]で無効
set textwidth=0

"ファイル候補が複数ある場合、共通する文字までを補完"
set wildmode=list:longest

"ファイルブラウザのデフォルトディレクトリ
set browsedir=buffer

"バッファ切り替え時、切り替え元バッファをhidden
set hidden

"インクリメンタルサーチ
set incsearch

"縦分割の新規ウィンドウは右に開く
set splitright

"横分割の新規ウィンドウは下に開く
set splitbelow

"検査をファイルの先頭へループしない"
set nowrapscan

"折りたたみ設定
set foldmethod=marker

"検索時に大文字を含んでいたら大/小を区別
set smartcase

"文字コードの自動認識
set fileencodings=ucs-bom,utf-8,iso-2022-jp,sjis,cp932,euc-jp,cp20932

"コマンドラインモードの保管を<Tab>でできるように
set wildmenu

"バックスペースで文字を消せるように
set backspace=indent,eol,start

"検索時に大文字小文字を無視する
set ignorecase

"大文字を混ぜて検索した場合だけ大文字小文字を区別する
set smartcase

"インクリメント時は常に10進数として判断
set nf=""

"}}}
"=======================================================

"=======================================================
"見た目 {{{
"=======================================================
"256色対応
set t_Co=256

"シンタックスハイライトをオン
syntax on

"カラースキーマ
"colorscheme jellybeans

if has("win32") || has("win64")
    "シンタックスハイライト
    au BufNewFile,BufRead *.log setf mpacs_log
endif

autocmd BufRead,BufNewFile *.mkd setfiletype mkd
autocmd BufRead,BufNewFile *.md setfiletype mkd

"入力モード時、ステータスラインのカラーを変更
"augroup InsertHook
"autocmd!
"    autocmd InsertEnter * highlight StatusLine ctermfg=#FFFFFF ctermbg=#000000 guifg=#FFFFFF guibg=#000000
"    autocmd InsertLeave * highlight StatusLine ctermfg=#000000 ctermbg=#FFFFFF guifg=#000000 guibg=#FFFFFF
"augroup END

"全角スペースを可視化
highlight JpSpace ctermbg=Blue
autocmd BufRead,BufNew * match JpSpace /　/

"カーソルのある行をハイライト
"set cursorline
"set cursorcolumn
"
"検索結果をハイライト
set hlsearch

"同じ括弧が入力された時、対応する括弧を表示
set showmatch

"括弧の強調表示をオフ
let loaded_matchparen=1

"文字コードと改行コードを表示
set statusline=%F%m%r%h%w\ [%Y][%{&fenc}%{&bomb?':BOM':':'}][%{&ff}][%04l,%04v][%p%%][LEN=%L]

"エディタウインドウの末尾から2行目にステータスラインを常時表示
set laststatus=2

"画面の端で折り返し
set wrap

"タブ文字、行末など不可視文字を表示する
set list

"listで表示される文字のフォーマットを指定
set listchars=eol:<,tab:>\ ,trail:-,extends:>,precedes:<

"タブ表示設定
"0 : 常に非表示
"1 : 2つ以上タブがあれば表示
"2 : 常に表示
set showtabline=2

"}}}
"=======================================================

"=======================================================
"インデント設定"{{{
"=======================================================

autocmd BufNewFile,BufRead * call SetIndent()

function! SetIndent()
  if &syntax=='ruby' || &syntax=='yaml' || &syntax=='vim' || &syntax=='eruby' || &syntax=='html'
    execute 'set softtabstop=2 | set shiftwidth=2 | set tabstop=2'
  else
    execute 'set softtabstop=4 | set shiftwidth=4 | set tabstop=4'
  endif
endf

set smarttab "新しい行を作った時に高度な自動インデント
set noautoindent "改行時に前の行のインデントを継続しない
set smartindent "改行時に入力された行の末尾に合わせて次の行のインデントを増減する
set cindent "Cプログラム用自動インデント
set expandtab "タブを使用しない

"}}}
"=======================================================

"=======================================================
"フォーマット"{{{
"=======================================================
"改行後の自動コメント挿入を解除
"r 挿入モードで<Enter>を打ち込んだ後にコメント開始文字列を自動挿入
"o ノーマルモードで'o','O'を打ち込んだ後にコメント開始文字列を自動挿入
"B マルチバイト文字と非マルチバイト文字の連結で間に空白を自動挿入
set formatoptions=qB
autocmd FileType * set formatoptions-=ro

"バイナリの編集モード
augroup Binary
    au!
    au BufReadPre   *.bin let &bin=1
    au BufReadPost  *.bin if &bin | %!xxd -g 1
    au BufReadPost  *.bin set ft=xxd | endif
    au BufWritePre  *.bin if &bin | %!xxd -r
    au BufWritePre  *.bin endif
    au BufWritePost *.bin if &bin | silent %!xxd -g 1
    au BufWritePost *.bin set nomod | endif
augroup END
"}}}
"=======================================================

"=======================================================
"自作コマンド"{{{
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
"}}}
"=======================================================

"=======================================================
" QuickRun設定 {{{
"=======================================================
let g:quickrun_config = {}
let g:quickrun_config = {
            \   '_': {
            \       'outputter/buffer/split': ':botright',
            \       'outputter/buffer/close_on_empty': 1,
            \       'hook/time/enable': '1'
            \   },
            \   'markdown': {
            \       'outputter': 'browser',
            \   }
            \}
"}}}
"=======================================================

"=======================================================
" neocomplcache設定"{{{
"=======================================================
let g:acp_enableAtStartup = 0
let g:neocomplcache_enable_at_startup = 1
let g:neocomplcache_enable_smart_case = 1
let g:neocomplcache_min_syntax_length = 3
let g:neocomplcache_lock_buffer_name_pattern = '\*ku\*'

let g:neocomplcache_dictionary_filetype_lists = {
  \ 'default' : ''
  \ }
"}}}

"=======================================================
" unite設定"{{{
"=======================================================
"unite general settings
"インサートモードで開始
let g:unite_enable_start_insert=1
"最近聞いたファイル履歴の保存数
let g:unite_source_file_mru_limit=50
"}}}
"=======================================================

"=======================================================
" vimfiler設定"{{{
"=======================================================
let g:vimfiler_as_default_explorer = 1"}}}
"=======================================================

"=======================================================
"matchit設定"{{{
"=======================================================
source $VIMRUNTIME/macros/matchit.vim
"}}}
"=======================================================

"=======================================================
"キーマッピング"{{{
"=======================================================

"-----------------------------
"nmap : ノーマルモード
"vmap : ビジュアルモード
"omap : モーション待ちモード
"imap : 挿入モード
"cmap : コマンドラインモード
"-----------------------------

"ESC押したときIMEオフ
"nmap <ESC> <ESC>:set iminsert=0<CR>

"ESCを連続で押したとき検索のハイライトを消す
nmap <ESC><ESC> :nohlsearch<CR><ESC>

"file_mruの表示フォーマットを指定。空にすると表示スピードが高速化
"let g:unite_source_file_mru_filename_format=''
"補完
imap <C-Space> <C-x><C-o>

"ファイルをタブで開くのをデフォルトにする
nnoremap gf <C-w>gF
nnoremap gF <C-w>gf
nnoremap <C-w>gf gF
nnoremap <C-w>gF gf

"--------------------------
"unite起動
"--------------------------
nnoremap [unite] <Nop>
nmap <Space>u [unite]

"現在開いているファイルのディレクトリ下のファイル一覧。
"開いていない場合はカレントディレクトリ
nnoremap <silent> [unite]f :<C-u>UniteWithBufferDir -buffer-name=files file<CR>
nnoremap <silent> [unite]o :<C-u>UniteWithBufferDir -buffer-name=files file<CR>
"バッファ一覧
nnoremap <silent> [unite]b :<C-u>Unite buffer<CR>
"レジスタ一覧
"nnoremap <silent> [unite]r :<C-u>-buffer-name=register register<CR>
"最近使用したファイル一覧
"nnoremap <silent> [unite]m :<C-u>Unite file_mru<CR>
"ブックマーク一覧
"nnoremap <silent> [unite]c :<C-u>Unite bookmark<CR>
"ブックマークに追加
"nnoremap <silent> [unite]a :<C-u>UniteBookmarkAdd<CR>

"--------------------------
"open-browser起動
"--------------------------
nnoremap [open-browser] <Nop>
nmap <Space>o [open-browser]
nmap <silent> [open-browser]s <Plug>(openbrowser-smart-search)
nmap <silent> [open-browser]o <Plug>(openbrowser-smart-search)

"--------------------------
"previm起動
"--------------------------
nnoremap [previm] <Nop>
nmap <Space>p [previm]
nmap <silent> [previm]o :<C-u>PrevimOpen<CR>

"-----------------------------
"uniteを開いている間のキーマッピング
"-----------------------------
autocmd FileType unite call s:unite_my_settings()

function! s:unite_my_settings()"{{{
    "ESC二回でuniteを終了
    nmap <buffer> <ESC><ESC> <Plug>(unite_exit)
    "入力モードのときjjでノーマルモードに移動
    imap <buffer> jj <Plug>(unite_insert_leave)
    "入力モードのときctrl+wでバックスラッシュも削除
    imap <buffer> <C-w> <Plug>(unite_delete_backward_path)
    "ctrl+jで縦に分割して開く
    nnoremap <silent> <buffer> <expr> <C-j> unite#do_action('split')
    inoremap <silent> <buffer> <expr> <C-j> unite#do_action('split')
    "ctrl+lで横に分割して開く
    nnoremap <silent> <buffer> <expr> <C-l> unite#do_action('vsplit')
    inoremap <silent> <buffer> <expr> <C-l> unite#do_action('vsplit')
    "ctrl+oでその場所に開く
    nnoremap <silent> <buffer> <expr> <C-o> unite#do_action('open')
    inoremap <silent> <buffer> <expr> <C-o> unite#do_action('open')
endfunction"}}}

"-----------------------------
"neocomplcache
"-----------------------------
inoremap <expr><C-g> neocomplcache#undo_completion()
inoremap <expr><C-l> neocomplcache#complete_common_string()

" Recommended key-mappings.
" <CR>: close popup and save indent.
inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function()
    return neocomplcache#smart_close_popup() . "\<CR>"
endfunction
" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> neocomplcache#smart_close_popup()."\<C-h>"
inoremap <expr><BS> neocomplcache#smart_close_popup()."\<C-h>"
inoremap <expr><C-y>  neocomplcache#close_popup()
inoremap <expr><C-e>  neocomplcache#cancel_popup()


"-----------------------------
"neosnippet
"-----------------------------
" Plugin key-mappings.
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
smap <C-k>     <Plug>(neosnippet_expand_or_jump)
xmap <C-k>     <Plug>(neosnippet_expand_target)

" SuperTab like snippets behavior.
"imap <expr><TAB>
" \ pumvisible() ? "\<C-n>" :
" \ neosnippet#expandable_or_jumpable() ?
" \    "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"
smap <expr><TAB> neosnippet#expandable_or_jumpable() ?
      \ "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"

" For conceal markers.
if has('conceal')
  set conceallevel=2 concealcursor=niv
endif

"}}}
"=======================================================

"=======================================================
" NeoBundleInstall自動化"{{{
"=======================================================
if(!empty(neobundle#get_not_installed_bundle_names()))
  echomsg 'Not installed bundles: '
        \ string(neobundle#get_not_installed_bundle_names())
  if confirm('Install bundles now?', "yes\nNo", 2) == 1
    " vimrc を再度読み込み、インストールした Bundle を有効化
    " vimrc は必ず再読み込み可能な形式で記述すること
    NeoBundleInstall
    source ~/.vimrc
  endif
end
"}}}
"=======================================================
