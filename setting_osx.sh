#!/bin/sh
cd `dirname $0`

if [ "$(uname)" != 'Darwin' ]; then
    echo Not mac
    exit -1
fi


echo Setting mac Start

defaults write NSGlobalDomain AppleShowAllExtensions -bool true    # 全ての拡張子のファイルを表示する
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true    # Fuキーを標準のファンクションキーとして使用

defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true    # USB やネットワークストレージに .DS_Store ファイルを作成しない
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

defaults write com.apple.finder ShowPathbar -bool true    # パスバーを表示する
defaults write com.apple.finder ShowTabView -bool true    # タブバーを表示する
defaults write com.apple.finder ShowStatusBar -bool true    # ステータスバーを表示する
defaults write com.apple.finder AppleShowAllFiles YES    # 不可視ファイルを表示する

defaults write com.apple.menuextra.clock 'DateFormat' -string 'EEE H:mm'    # 日付表示設定、曜日を表示

echo Setting mac Completed

