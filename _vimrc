"=======================================================
"初期設定
"=======================================================
"vi互換オフ
set nocompatible
"ファイルタイプを一時的にオフ
filetype off

"vundle初期化"
if has("win32") || has("win64")
    set rtp+=~/vimfiles/vundle.git/
    call vundle#rc('~/vimfiles/bundle/')
else
    set rtp+=~/.vim/vundle.git/
    call vundle#rc()
endif

"ファイルタイプをオン
filetype plugin indent on


"=======================================================
"基本設定設定
"=======================================================
"スワップファイルの出力先設定
set directory=~/dotfiles/tmp

"チルダファイルの出力先設定
set nobackup

"viminfoの出力先設定
set viminfo+=n~/dotfiles/tmp/viminfo.txt

"行表示
set number

"クリップボードを利用
set clipboard=unnamed

"入力されているテキストの最大幅 [0]で無効
set textwidth=0

"新しい行を作った時に高度な自動インデント
set smarttab

"ファイル候補が複数ある場合、共通する文字までを補完"
set wildmode=list:longest

"ファイルブラウザのデフォルトディレクトリ
set browsedir=buffer

"=======================================================
"見た目
"=======================================================
"シンタックスハイライトをオン
syntax on

"256色対応
set t_Co=256

"カラースキーマ
colorscheme desert

"シンタックスハイライト
"au BufNewFile,BufRead *.log setf mpacs_log

"入力モード時、ステータスラインのカラーを変更
"augroup InsertHook
"	autocmd!
"	autocmd InsertEnter * highlight StatusLine guifg=#FFFFFF guibg=#000000
"	autocmd InsertLeave * highlight StatusLine guifg=#000000 guibg=#FFFFFF
"augroup END

"全角スペースを可視化
highlight JpSpace ctermbg=Blue guibg=Blue
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
set statusline=statusline=%F%m%r%h%w\ [%{&ff}]\ [%Y]\ [POS=%04l,%04v][%p%%]\ [LEN=%L]

"エディタウインドウの末尾から2行目にステータスラインを常時表示
set laststatus=2

"画面の端で折り返し
set wrap

"タブ文字、行末など不可視文字を表示する
set list

"listで表示される文字のフォーマットを指定
set listchars=eol:<,tab:>\ ,trail:-,extends:>,precedes:<

"=======================================================
"インデント設定
"=======================================================
"ファイル内の<Tab>が対応する空白の数
set tabstop=4

"<Tab>の挿入や<BS>の使用の編集操作をするときに、<Tab>が対応する空白数
set softtabstop=4

"自動インデントの各段階に使われる空白数
set shiftwidth=4

"オートインデントオフ
set noautoindent

"Cプログラム用自動インデント
set cindent

"=======================================================
"キーマッピング
"=======================================================
"--------------------------
"   ノーマルモード(nmap)
"--------------------------

"_vimrcと_gvimrcの編集用ショートカット
nmap <Space>ev :<C-u>tabnew $MYVIMRC<CR>
nmap <Space>eg :<C-u>tabnew $MYGVIMRC<CR>

"ESC押したときIMEオフ
nmap <ESC> <ESC>:set iminsert=0<CR>

"ESCを連続で押したとき検索のハイライトを消す
nmap <ESC><ESC> :nohlsearch<CR><ESC>

"--------------------------
"  ビジュアルモード(vmap)
"--------------------------


"--------------------------
"モーション待ちモード(omap)
"--------------------------
"
"
"--------------------------
"     挿入モード(imap)
"--------------------------
"
"ESC押したときIMEオフ
imap <ESC> <ESC>:set iminsert=0<CR>

"括弧やクオートなどを入力した際に左に自動で移動
imap {<Space>} {}<Left>
imap [<Space>] []<Left>
imap (<Space>) ()<Left>
imap "<Space>" ""<Left>
imap '<Space>' ''<Left>
imap <<Space>> <><Left>

"--------------------------
"コマンドラインモード(cmap)
"--------------------------
"
