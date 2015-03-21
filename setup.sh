#!/bin/sh
echo ---- dotfiles setup start ----
echo make link
ln -sf ~/dotfiles/_vimrc ~/.vimrc
ln -sf ~/dotfiles/_gvimrc ~/.gvimrc
ln -sf ~/dotfiles/vimfiles ~/.vim
ln -sf ~/dotfiles/.gitconfig ~/.gitconfig
 
echo submodule init and update
FirstDir=`pwd`
cd `dirname $0`
git submodule init
git submodule update
cd $FirstDir

echo vim init
vim +":NeoBundleInstall" +":q"

echo ---- dotfiles setup end ----
