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

# 管理ブロックの開始/終了マーカー（追記・撤去の目印に使う）
DOTFILES_BLOCK_BEGIN="# >>> dotfiles managed block >>>"
DOTFILES_BLOCK_END="# <<< dotfiles managed block <<<"

# シェル設定（.bashrc 等）へ source 行を冪等に追記する。
# symlink で置き換えないため、devcontainer などで既に配置済みのファイルの内容を
# 活かしたまま dotfiles の共通設定（shell/*.sh）を読み込める。
#   - 旧方式で張られた dotfiles への symlink は実体ファイルへ作り直す（移行対応）
#   - 実体が無ければ管理ブロックだけのファイルを新規作成する
#   - 既存ファイルに管理ブロックが無ければ末尾へ追記する（既存内容は保持）
ensure_managed_block() {
    target="$1"
    body="$2"

    # 旧方式（dotfiles を指す symlink）なら撤去して実体ファイルへ移行する
    if [ -L "$target" ]; then
        case "$(readlink "$target")" in
            "$HOME"/dotfiles/*)
                echo "convert legacy symlink to file: $target"
                rm -f "$target"
                ;;
        esac
    fi

    if [ ! -e "$target" ]; then
        printf '%s\n%s\n%s\n' "$DOTFILES_BLOCK_BEGIN" "$body" "$DOTFILES_BLOCK_END" > "$target"
        echo "create $target"
        return
    fi

    if grep -qF "$DOTFILES_BLOCK_BEGIN" "$target" 2>/dev/null; then
        echo "managed block already present in $target"
    else
        printf '\n%s\n%s\n%s\n' "$DOTFILES_BLOCK_BEGIN" "$body" "$DOTFILES_BLOCK_END" >> "$target"
        echo "append managed block to $target"
    fi
}

# ensure_managed_block で追記した管理ブロックを撤去する（ファイル本体は残す）
remove_managed_block() {
    target="$1"
    [ -f "$target" ] || return 0
    grep -qF "$DOTFILES_BLOCK_BEGIN" "$target" 2>/dev/null || return 0

    _tmp="$(mktemp)"
    sed "/^${DOTFILES_BLOCK_BEGIN}$/,/^${DOTFILES_BLOCK_END}$/d" "$target" > "$_tmp" && mv "$_tmp" "$target"
    echo "remove managed block from $target"
}

deploy() {
    echo make link
    link_file ~/dotfiles/_vimrc ~/.vimrc

    # シェル設定は symlink で置き換えず source 行を追記する（既存ファイルを活かす）
    ensure_managed_block ~/.bashrc '. "$HOME/dotfiles/shell/rc.sh"'
    ensure_managed_block ~/.zshrc '. "$HOME/dotfiles/shell/rc.sh"'
    ensure_managed_block ~/.zprofile '. "$HOME/dotfiles/shell/profile.sh"'
    # ログインシェル（.bash_profile）でも環境変数・エイリアスを読み込む
    ensure_managed_block ~/.bash_profile '. "$HOME/dotfiles/shell/profile.sh"
. "$HOME/dotfiles/shell/rc.sh"'

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
    [ -L ~/.vimrc ] && unlink ~/.vimrc

    # シェル設定は管理ブロックのみ撤去する（既存ファイル本体は残す）。
    # 旧方式で張られた dotfiles への symlink が残っていれば併せて撤去する。
    for f in ~/.bashrc ~/.zshrc ~/.zprofile ~/.bash_profile; do
        if [ -L "$f" ]; then
            case "$(readlink "$f")" in
                "$HOME"/dotfiles/*) unlink "$f" ;;
            esac
        else
            remove_managed_block "$f"
        fi
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
