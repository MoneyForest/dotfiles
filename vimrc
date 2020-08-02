" 色関連
colorscheme default          " カラースキーム
syntax on                    " シンタックスカラーリングオン
filetype indent on           " ファイルタイプによるインデントを行う
filetype plugin on           " ファイルタイプごとのプラグインを使う
highlight Pmenu ctermbg=lightcyan ctermfg=black
highlight PmenuSel ctermbg=blue ctermfg=black
highlight PmenuSbar ctermbg=darkgray
highlight PmenuThumb ctermbg=lightgray
highlight Comment ctermfg=blue


" エンコーディング関連
set encoding=utf-8
set fileencodings=utf-8,euc-jp,iso-2022-jp,cp932,sjis
set fileformats=unix,dos,mac


" 表示関連
set showmatch         " 括弧の対応をハイライト
set showcmd           " 入力中のコマンドを表示
set wrap              " 画面幅で折り返す
"set list              " 不可視文字表示
set notitle           " タイトル書き換えない
set scrolloff=5       " 行送り


" Tab関連
set tabstop=2
set softtabstop=0
set expandtab      " タブを空白文字に展開


" 検索関連
set wrapscan   " 最後まで検索したら先頭へ戻る
set ignorecase " 大文字小文字無視
set smartcase  " 大文字ではじめたら大文字小文字無視しない
set incsearch  " インクリメンタルサーチ
set hlsearch   " 検索文字をハイライト
