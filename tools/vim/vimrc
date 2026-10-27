"=======================================================
"基本設定
"=======================================================
set incsearch "インクリメンタルサーチ(1文字入力ごとに検索）
set nowrapscan "検査をファイルの先頭へループしない"
set smartcase "大文字を混ぜて検索した場合だけ大文字小文字を区別する
set ignorecase "検索時に大文字小文字を無視する
set wildmenu "マンドラインモードの補完候補をステータスラインに表示きるように


"=======================================================
"見た目
"=======================================================
syntax on "シンタックスハイライトをオン
colorscheme industry "カラースキーマ
set number "行表示
set hlsearch "検索結果をハイライト
set showmatch "同じ括弧が入力された時、対応する括弧を表示
set matchtime=1 "対応するカッコを表示する時間（単位:0.1秒）

"文字コードと改行コードを表示
if exists("ALEGetStatusLine")
    set statusline=%F%m%r%h%w\ [%Y][%{&fenc}%{&bomb?':BOM':':'}][%{&ff}][%04l,%04v][%p%%][LEN=%L]%{ALEGetStatusLine()}
else
    set statusline=%F%m%r%h%w\ [%Y][%{&fenc}%{&bomb?':BOM':':'}][%{&ff}][%04l,%04v][%p%%][LEN=%L]
endif

set laststatus=2 "エディタウインドウの末尾から2行目にステータスラインを常時表示
set wrap "画面の端で折り返し
set list "タブ文字、行末など不可視文字を表示する
set listchars=eol:<,tab:>\ ,trail:-,extends:>,precedes:< "listで表示される文字のフォーマットを指定

"タブ表示設定
"0 : 常に非表示
"1 : 2つ以上タブがあれば表示
"2 : 常に表示
set showtabline=2

set pumheight=10 "補完メニューの高さ


"=======================================================
"インデント設定
"=======================================================
set tabstop=4
set softtabstop=4
set shiftwidth=4

set smarttab "新しい行を作った時に高度な自動インデント
set noautoindent "オートインデントオフ


"=======================================================
"キーマッピング
"=======================================================
"ESCを連続で押したとき検索のハイライトを消す
nmap <ESC><ESC> :nohlsearch<CR><ESC>
