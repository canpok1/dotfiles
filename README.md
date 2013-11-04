dotfiles
========

### セットアップ方法
1. githubからファイルを持ってくる

    git clone http://github.com/canpok1/dotfiles.git ~/dotfiles

2. vundleの配置のためにsubmoduleのinitとupdate

    cd ~/dotfiles
    git submodule init
    git submodule update
    
3. シンボリックリンクの作成

    mklink C:\Users\xxxx\_vimrc C:\Users\xxxx\dotfiles\_vimrc
    mklink C:\Users\xxxx\_gvimrc C:\Users\xxxx\dotfiles\_gvimrc
    mklink /d C:\Users\xxxx\vimfiles C:\Users\xxxx\dotfiles\vimfiles
    
4. vimを起動して各種プラグインのインストール

    :BundleInstall
