#!/bin/sh
ln -sf ~/dotfiles/_vimrc ~/.vimrc
ln -sf ~/dotfiles/_gvimrc ~/.gvimrc
ln -sfd ~/dotfiles/vimfiles ~/.vim
ln -sf ~/dotfiles/.gitconfig ~/.gitconfig

FirstDir=`pwd`
cd `dirname $0`
git submodule init
git submodule update
cd $FirstDir

vim +":NeoBundleInstall" +":q"
