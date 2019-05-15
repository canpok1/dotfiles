"=======================================================
"ファイルタイプ設定
"=======================================================
au BufRead,BufNewFile *.gradle set filetype=groovy
au BufRead,BufNewFile *.{md,mdwn,mkd,mkdn} set filetype=markdown


"=======================================================
"基本設定 
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

"アンドゥファイルの出力設定
set noundofile

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



"=======================================================
"見た目 
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
if exists("ALEGetStatusLine")
    set statusline=%F%m%r%h%w\ [%Y][%{&fenc}%{&bomb?':BOM':':'}][%{&ff}][%04l,%04v][%p%%][LEN=%L]%{ALEGetStatusLine()}
else
    set statusline=%F%m%r%h%w\ [%Y][%{&fenc}%{&bomb?':BOM':':'}][%{&ff}][%04l,%04v][%p%%][LEN=%L]
endif

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



"=======================================================
"インデント設定
"=======================================================
set tabstop=4
set softtabstop=4
set shiftwidth=4

"新しい行を作った時に高度な自動インデント
set smarttab

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

"ノーマルモードではセミコロンをコロンに
nnoremap ; :

