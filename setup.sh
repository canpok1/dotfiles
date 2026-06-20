#!/bin/sh
cd `dirname $0`

if [ "$(uname)" = 'Darwin' ]; then
    echo setup for mac
elif [ "$(expr substr $(uname -s) 1 5)" = 'Linux' ]; then
    echo setup for linux
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

    # Claude 個人設定（CLAUDE.md / agents / skills / rules）を ~/.claude へ展開する
    mkdir -p ~/.claude/skills ~/.claude/agents ~/.claude/rules
    ln -fnsv ~/dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md
    for agent in ~/dotfiles/claude/agents/*.md; do
        [ -e "$agent" ] || continue
        ln -fnsv "$agent" ~/.claude/agents/"$(basename "$agent")"
    done
    for skill_dir in ~/dotfiles/claude/skills/*/; do
        [ -e "$skill_dir" ] || continue
        ln -fnsv "${skill_dir%/}" ~/.claude/skills/"$(basename "$skill_dir")"
    done
    for rule in ~/dotfiles/claude/rules/*; do
        [ -e "$rule" ] || continue
        ln -fnsv "$rule" ~/.claude/rules/"$(basename "$rule")"
    done
}

undeploy() {
    unlink ~/.vimrc
    unlink ~/.gvimrc
    unlink ~/.vim
    unlink ~/.gitconfig
    unlink ~/.bash_profile
    unlink ~/.bashrc
    unlink ~/.Brewfile

    # Claude 個人設定の symlink を撤去する。
    # dotfiles 側の現状ではなく、~/.claude 配下で dotfiles を指している
    # 既存 symlink を動的に検出して外す（追加/削除後の張り直しでも取りこぼさない）。
    if [ -d ~/.claude ]; then
        find ~/.claude -type l | while read -r link; do
            case "$(readlink "$link")" in
                "$HOME"/dotfiles/*) unlink "$link" 2>/dev/null || true ;;
            esac
        done
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
    # Brewfile を適用する（mac / Linux 両対応。vox-actor もここで導入される）
    if command -v brew >/dev/null 2>&1; then
        brew bundle --global
    else
        echo "brew not found; skip brew bundle" >&2
    fi
    # Todoist CLI (td) を導入する（workflow-scripts が利用）
    if ! command -v td >/dev/null 2>&1; then
        if command -v npm >/dev/null 2>&1; then
            npm install -g @doist/todoist-cli
        else
            echo "npm not found; skip td install" >&2
        fi
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
    echo ---- initialize end ----
else
    echo ---- dotfiles setup start ----
    deploy
    echo ---- dotfiles setup end ----
fi
