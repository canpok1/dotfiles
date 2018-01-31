@echo off
mklink %USERPROFILE%\_vimrc %~dp0\_vimrc
mklink %USERPROFILE%\_gvimrc %~dp0\_gvimrc
mklink /d %USERPROFILE%\vimfiles %~dp0\vimfiles
mklink %USERPROFILE%\.gitconfig %~dp0\.gitconfig

mklink /d %AppData%\Code\User %~dp0\vscode

pushd %~dp0
git submodule init
git submodule update
popd
