"=======================================================
"プラグイン設定
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
	let g:vundle_default_git_proto='git'
    call vundle#rc()
endif

"vim-scriptsリポジトリ

"githubの任意のリポジトリ
Bundle 'Shougo/unite.vim'

"github以外のリポジトリ

"ファイル形式検出、プラグイン、インデントをオン
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

"バッファ切り替え時、切り替え元バッファをhidden
set hidden

"インクリメンタルサーチ
set incsearch

"vimの内部文字エンコーディング
:set encoding=utf-8

"文字エンコーディング
:set fileencodings=ucs-bom,iso-2022-jp-3,iso-2022-jp,eucjp-ms,euc-jisx0213,euc-jp,sjis,cp932,utf-8

"縦分割の新規ウィンドウは右に開く
set splitright

"=======================================================
"見た目
"=======================================================
"256色対応
set t_Co=256

"シンタックスハイライトをオン
syntax on

"カラースキーマ
colorscheme jellybeans

"シンタックスハイライト
"au BufNewFile,BufRead *.log setf mpacs_log

"入力モード時、ステータスラインのカラーを変更
"augroup InsertHook
"autocmd!
"	autocmd InsertEnter * highlight StatusLine ctermfg=#FFFFFF ctermbg=#000000 guifg=#FFFFFF guibg=#000000
"	autocmd InsertLeave * highlight StatusLine ctermfg=#000000 ctermbg=#FFFFFF guifg=#000000 guibg=#FFFFFF
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
set statusline=%F%m%r%h%w\ [%Y][%{&fenc}][%{&ff}][%04l,%04v][%p%%][LEN=%L]

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

"タブを使用しない
set expandtab

"=======================================================
"フォーマット
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

"=======================================================
"キーマッピング
"=======================================================
"--------------------------
"   ノーマルモード(nmap)
"--------------------------

"_vimrcと_gvimrcの編集用ショートカット
"nmap <Space>ev :<C-u>tabnew $MYVIMRC<CR>
"nmap <Space>eg :<C-u>tabnew $MYGVIMRC<CR>

"ESC押したときIMEオフ
"nmap <ESC> <ESC>:set iminsert=0<CR>

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
"imap <ESC> <ESC>:set iminsert=0<CR>

"括弧やクオートなどを入力した際に左に自動で移動
"imap {<Space>} {}<Left>
"imap [<Space>] []<Left>
"imap (<Space>) ()<Left>
"imap '<Space>' ''<Left>
"imap <<Space>> <><Left>

"--------------------------
"コマンドラインモード(cmap)
"--------------------------




"--------------------------
"unite設定
"--------------------------
"unite prefix key.
nnoremap [unite] <Nop>
nmap <Space>u [unite]

"unite general settings
"インサートモードで開始
let g:unite_enable_start_insert=1
"最近聞いたファイル履歴の保存数
let g:unite_source_file_mru_limit=50

"file_mruの表示フォーマットを指定。空にすると表示スピードが高速化
"let g:unite_source_file_mru_filename_format=''

"現在開いているファイルのディレクトリ下のファイル一覧。
"開いていない場合はカレントディレクトリ
nnoremap <silent> [unite]f :<C-u>UniteWithBufferDir -buffer-name=files file<CR>
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
"uniteを開いている間のキーマッピング
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
