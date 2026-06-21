#!/bin/sh
cd "$(dirname "$0")" || exit 1

if [ "$(uname)" = 'Darwin' ]; then
    echo setup for mac
elif [ "$(expr substr $(uname -s) 1 5)" = 'Linux' ]; then
    echo setup for linux
else
    echo "OS is unknown. exit setup."
    exit 1
fi

# 既存の実体（symlink でない通常ファイル/ディレクトリ）があれば .bak に退避する。
# 既に symlink の場合は退避しない（再実行時はそのまま張り替える）。
backup_if_real() {
    if [ -e "$1" ] && [ ! -L "$1" ]; then
        _bak="$1.bak"
        if [ -e "$_bak" ]; then
            _bak="$1.bak.$(date +%Y%m%d%H%M%S)"
        fi
        echo "backup $1 -> $_bak"
        mv "$1" "$_bak"
    fi
}

# 実体があればバックアップしてから symlink を張る
link_file() {
    backup_if_real "$2"
    ln -fnsv "$1" "$2"
}

deploy() {
    echo make link
    link_file ~/dotfiles/_vimrc ~/.vimrc
    link_file ~/dotfiles/.bash_profile ~/.bash_profile
    link_file ~/dotfiles/.bashrc ~/.bashrc
    link_file ~/dotfiles/.zprofile ~/.zprofile
    link_file ~/dotfiles/.zshrc ~/.zshrc

    touch ~/.shell_local

    # Claude 個人設定（CLAUDE.md / settings.json / statusline.sh / agents / skills / rules）を ~/.claude へ展開する
    mkdir -p ~/.claude/skills ~/.claude/agents ~/.claude/rules
    link_file ~/dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md
    link_file ~/dotfiles/claude/settings.json ~/.claude/settings.json
    link_file ~/dotfiles/claude/statusline.sh ~/.claude/statusline.sh
    for agent in ~/dotfiles/claude/agents/*.md; do
        [ -e "$agent" ] || continue
        link_file "$agent" ~/.claude/agents/"$(basename "$agent")"
    done
    for skill_dir in ~/dotfiles/claude/skills/*/; do
        [ -e "$skill_dir" ] || continue
        link_file "${skill_dir%/}" ~/.claude/skills/"$(basename "$skill_dir")"
    done
    for rule in ~/dotfiles/claude/rules/*; do
        [ -e "$rule" ] || continue
        link_file "$rule" ~/.claude/rules/"$(basename "$rule")"
    done
}

undeploy() {
    # symlink のものだけ撤去する（実体ファイルや未デプロイ時は触らない）
    for f in ~/.vimrc ~/.bash_profile ~/.bashrc ~/.zprofile ~/.zshrc; do
        [ -L "$f" ] && unlink "$f"
    done

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
    # vox-actor を公式インストーラで導入する（mac / Linux 両対応）
    if ! command -v vox-actor >/dev/null 2>&1; then
        curl -fsSL https://github.com/canpok1/vox-actor/releases/latest/download/install.sh | bash
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
