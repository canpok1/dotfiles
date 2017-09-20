#!/bin/sh
cd `dirname $0`

OS="unknown"
if [ "$(uname)" == 'Darwin' ]; then
    echo setup for mac
    OS="mac"
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
    echo setup for linux
    OS="linux"
else
    echo "OS is unknown. exit setup."
    return -1
fi

function deploy() {
    echo make link
    ln -fnsv ~/dotfiles/_vimrc ~/.vimrc
    ln -fnsv ~/dotfiles/_gvimrc ~/.gvimrc
    ln -fnsv ~/dotfiles/vimfiles ~/.vim
    ln -fnsv ~/dotfiles/.gitconfig ~/.gitconfig
    
    if [ "$OS" == "mac" ]; then
        ln -fnsv ~/dotfiles/vscode ~/Library/Application\ Support/Code/User
    elif [ "$OS" == 'linux' ]; then
        echo setup for linux
    fi
}

function install() {
    echo submodule init and update
    git submodule init
    git submodule update
}

function undeploy() {
    unlink ~/.vimrc
    unlink ~/.gvimrc
    unlink ~/.vim
    unlink ~/.gitconfig

    if [ "$OS" == "mac" ]; then
        unlink ~/Library/Application\ Support/Code/User
    elif [ "$OS" == 'linux' ]; then
        echo uninstall for linux
    fi
}

if [ "$1" == "--uninstall" ]; then
    echo ---- dotfiles uninstall start ----
    undeploy
    echo ---- dotfiles uninstall end ----
else
    echo ---- dotfiles setup start ----
    deploy
    install
    echo ---- dotfiles setup end ----
fi
