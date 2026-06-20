#!/bin/sh
cd `dirname $0`

OS="unknown"
if [ "$(uname)" = 'Darwin' ]; then
    echo setup for mac
    OS="mac"
elif [ "$(expr substr $(uname -s) 1 5)" = 'Linux' ]; then
    echo setup for linux
    OS="linux"
else
    echo "OS is unknown. exit setup."
    exit 1
fi

deploy() {
    echo make link
    ln -fnsv ~/dotfiles/_vimrc ~/.vimrc
    ln -fnsv ~/dotfiles/_gvimrc ~/.gvimrc
    ln -fnsv ~/dotfiles/vimfiles ~/.vim
    ln -fnsv ~/dotfiles/.gitconfig ~/.gitconfig
    ln -fnsv ~/dotfiles/.bash_profile ~/.bash_profile
    ln -fnsv ~/dotfiles/.bashrc ~/.bashrc
    ln -fnsv ~/dotfiles/.Brewfile ~/.Brewfile
    
    touch ~/.bash_profile_local
    touch ~/.gitconfig.local
}

deploy_vscode() {
    if [ "$OS" = "mac" ]; then
        ln -fnsv ~/dotfiles/vscode ~/Library/Application\ Support/Code/User
    fi
}

undeploy() {
    unlink ~/.vimrc
    unlink ~/.gvimrc
    unlink ~/.vim
    unlink ~/.gitconfig
    unlink ~/.bash_profile
    unlink ~/.bashrc
    unlink ~/.Brewfile

    if [ "$OS" = "mac" ]; then
        unlink ~/Library/Application\ Support/Code/User
    elif [ "$OS" = 'linux' ]; then
        echo uninstall for linux
    fi
}

initialize() {
    if [ "$OS" = "mac" ]; then
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        brew bundle --global
    fi
}

if [ "$1" = "--undeploy" ]; then
    echo ---- dotfiles undeploy start ----
    undeploy
    echo ---- dotfiles undeploy end ----
elif [ "$1" = "--init" ]; then
    echo ---- initialize start ----
    deploy
    initialize
    deploy_vscode
    echo ---- initialize end ----
else
    echo ---- dotfiles setup start ----
    deploy
    deploy_vscode
    echo ---- dotfiles setup end ----
fi
