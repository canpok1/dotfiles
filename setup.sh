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
    # Homebrew 未導入なら導入する（mac / Linux 共通インストーラ）
    if ! command -v brew >/dev/null 2>&1 && [ ! -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    # Linux 版 Homebrew を PATH に通す
    if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
    # Brewfile を適用する（mac / Linux 両対応）
    if command -v brew >/dev/null 2>&1; then
        brew bundle --global
    else
        echo "brew not found; skip brew bundle" >&2
    fi
}

# vox-radio 個人設定（Claude スキル/agents/CLAUDE.md）を ~/.claude へ展開する。
# Todoist 連携スキルは vox-radio 専用のため opt-in（--vox-radio）でのみ実行する。
deploy_claude() {
    echo deploy claude config
    mkdir -p ~/.claude/skills ~/.claude/agents
    ln -fnsv ~/dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md
    ln -fnsv ~/dotfiles/claude/agents/task-assigner.md ~/.claude/agents/task-assigner.md
    for skill_dir in ~/dotfiles/claude/skills/*/; do
        skill_name=$(basename "$skill_dir")
        ln -fnsv ~/dotfiles/claude/skills/"$skill_name" ~/.claude/skills/"$skill_name"
    done
}

# workflow-scripts が依存するツール（td / vox-actor）を導入する。
install_vox_radio_tools() {
    echo install vox-radio tools
    # Todoist CLI (td)
    if ! command -v td >/dev/null 2>&1; then
        npm install -g @doist/todoist-cli
    fi
    # vox-actor (Homebrew cask)
    if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
    if command -v brew >/dev/null 2>&1 && ! brew list --cask vox-actor >/dev/null 2>&1; then
        brew tap canpok1/tap
        brew trust canpok1/tap
        brew install --cask vox-actor
    fi
}

undeploy_claude() {
    echo undeploy claude config
    unlink ~/.claude/CLAUDE.md 2>/dev/null || true
    unlink ~/.claude/agents/task-assigner.md 2>/dev/null || true
    for skill_dir in ~/dotfiles/claude/skills/*/; do
        skill_name=$(basename "$skill_dir")
        unlink ~/.claude/skills/"$skill_name" 2>/dev/null || true
    done
}

if [ "$1" = "--undeploy" ]; then
    echo ---- dotfiles undeploy start ----
    undeploy
    undeploy_claude
    echo ---- dotfiles undeploy end ----
elif [ "$1" = "--init" ]; then
    echo ---- initialize start ----
    deploy
    initialize
    deploy_vscode
    echo ---- initialize end ----
elif [ "$1" = "--vox-radio" ]; then
    echo ---- vox-radio setup start ----
    deploy_claude
    install_vox_radio_tools
    echo ---- vox-radio setup end ----
else
    echo ---- dotfiles setup start ----
    deploy
    deploy_vscode
    echo ---- dotfiles setup end ----
fi
