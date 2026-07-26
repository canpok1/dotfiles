#!/bin/sh
# このスクリプトが置かれているディレクトリを dotfiles の実体として扱う
# （~/dotfiles 以外へ clone しても、実行したクローンが正しくリンクされる）
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd -P)" || exit 1
cd "$DOTFILES_DIR" || exit 1

# 旧デフォルト配置。過去に ~/dotfiles から展開した symlink の撤去に使う
LEGACY_DOTFILES_DIR="$HOME/dotfiles"

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

# symlink を撤去し、撤去した内容を表示する。
# unlink は ln -v のような表示機能を持たないため、ここで自前に出力する
# （deploy 側の `'A' -> 'B'` 表示と対になる）。
unlink_file() {
    _dest="$(readlink "$1")"
    unlink "$1" 2>/dev/null && echo "unlink $1 -> $_dest"
    return 0
}

# symlink の参照先が dotfiles（実行中のクローン or 旧デフォルト配置）配下かを判定する
is_dotfiles_link() {
    case "$(readlink "$1")" in
        "$DOTFILES_DIR"/* | "$LEGACY_DOTFILES_DIR"/*) return 0 ;;
    esac
    return 1
}

# 管理ブロックの開始/終了マーカー（追記・撤去の目印に使う）
DOTFILES_BLOCK_BEGIN="# >>> dotfiles managed block >>>"
DOTFILES_BLOCK_END="# <<< dotfiles managed block <<<"

# ensure_managed_block で追記した管理ブロックを撤去する（ファイル本体は残す）
# 書き戻しは cat のリダイレクトで行い、元ファイルのパーミッションを維持する
remove_managed_block() {
    target="$1"
    [ -f "$target" ] || return 0
    grep -qF "$DOTFILES_BLOCK_BEGIN" "$target" 2>/dev/null || return 0

    _tmp="$(mktemp)"
    sed "/^${DOTFILES_BLOCK_BEGIN}$/,/^${DOTFILES_BLOCK_END}$/d" "$target" > "$_tmp" && cat "$_tmp" > "$target"
    rm -f "$_tmp"
    echo "remove managed block from $target"
}

# 末尾の空行を取り除く（管理ブロックの張り替えで空行が増え続けるのを防ぐ）
strip_trailing_blank_lines() {
    _tmp="$(mktemp)"
    # コマンド置換は末尾の改行を落とすため、これで末尾の空行がまとめて除かれる
    printf '%s\n' "$(cat "$1")" > "$_tmp" && cat "$_tmp" > "$1"
    rm -f "$_tmp"
}

# シェル設定（.bashrc 等）へ source 行を冪等に配置する。
# symlink で置き換えないため、devcontainer などで既に配置済みのファイルの内容を
# 活かしたまま dotfiles の共通設定（shell/*.sh）を読み込める。
#   - 旧方式で張られた dotfiles への symlink は実体ファイルへ作り直す（移行対応）
#   - 実体が無ければ管理ブロックだけのファイルを新規作成する
#   - 既存ファイルに管理ブロックが無ければ末尾へ追記する（既存内容は保持）
#   - 既に管理ブロックがあれば最新内容へ張り替える
#     （dotfiles の配置を変えた場合にブロック内のパスを追従させるため）
ensure_managed_block() {
    target="$1"
    body="$2"

    # 旧方式（dotfiles を指す symlink）なら撤去して実体ファイルへ移行する
    if [ -L "$target" ] && is_dotfiles_link "$target"; then
        echo "convert legacy symlink to file: $target"
        rm -f "$target"
    fi

    if [ ! -e "$target" ]; then
        printf '%s\n%s\n%s\n' "$DOTFILES_BLOCK_BEGIN" "$body" "$DOTFILES_BLOCK_END" > "$target"
        echo "create $target"
        return
    fi

    if grep -qF "$DOTFILES_BLOCK_BEGIN" "$target" 2>/dev/null; then
        remove_managed_block "$target" > /dev/null
        strip_trailing_blank_lines "$target"
        _action=update
    else
        _action=append
    fi
    printf '\n%s\n%s\n%s\n' "$DOTFILES_BLOCK_BEGIN" "$body" "$DOTFILES_BLOCK_END" >> "$target"
    echo "$_action managed block in $target"
}

deploy() {
    echo "make link (dotfiles: $DOTFILES_DIR)"
    link_file "$DOTFILES_DIR/_vimrc" ~/.vimrc

    # シェル設定は symlink で置き換えず source 行を追記する（既存ファイルを活かす）。
    # ブロック先頭で DOTFILES_DIR を export し、shell/*.sh からも参照できるようにする
    # （source される側は自分の位置を特定できないため）。
    _export_line="export DOTFILES_DIR=\"$DOTFILES_DIR\""
    ensure_managed_block ~/.bashrc "$_export_line
. \"\$DOTFILES_DIR/shell/rc.sh\""
    ensure_managed_block ~/.zshrc "$_export_line
. \"\$DOTFILES_DIR/shell/rc.sh\""
    ensure_managed_block ~/.zprofile "$_export_line
. \"\$DOTFILES_DIR/shell/profile.sh\""
    # ログインシェル（.bash_profile）でも環境変数・エイリアスを読み込む
    ensure_managed_block ~/.bash_profile "$_export_line
. \"\$DOTFILES_DIR/shell/profile.sh\"
. \"\$DOTFILES_DIR/shell/rc.sh\""

    touch ~/.shell_local

    # Claude 個人設定（CLAUDE.md / settings.json / statusline.sh / agents / skills / rules）を ~/.claude へ展開する
    mkdir -p ~/.claude/skills ~/.claude/agents ~/.claude/rules
    link_file "$DOTFILES_DIR/claude/CLAUDE.md" ~/.claude/CLAUDE.md
    link_file "$DOTFILES_DIR/claude/settings.json" ~/.claude/settings.json
    link_file "$DOTFILES_DIR/claude/statusline.sh" ~/.claude/statusline.sh
    for agent in "$DOTFILES_DIR"/claude/agents/*.md; do
        [ -e "$agent" ] || continue
        link_file "$agent" ~/.claude/agents/"$(basename "$agent")"
    done
    for skill_dir in "$DOTFILES_DIR"/claude/skills/*/; do
        [ -e "$skill_dir" ] || continue
        link_file "${skill_dir%/}" ~/.claude/skills/"$(basename "$skill_dir")"
    done
    for rule in "$DOTFILES_DIR"/claude/rules/*; do
        [ -e "$rule" ] || continue
        link_file "$rule" ~/.claude/rules/"$(basename "$rule")"
    done
}

undeploy() {
    # dotfiles を指す symlink だけ撤去する（実体ファイルや未デプロイ時は触らない）
    if [ -L ~/.vimrc ] && is_dotfiles_link ~/.vimrc; then
        unlink_file ~/.vimrc
    fi

    # シェル設定は管理ブロックのみ撤去する（既存ファイル本体は残す）。
    # 旧方式で張られた dotfiles への symlink が残っていれば併せて撤去する。
    for f in ~/.bashrc ~/.zshrc ~/.zprofile ~/.bash_profile; do
        if [ -L "$f" ]; then
            is_dotfiles_link "$f" && unlink_file "$f"
        else
            remove_managed_block "$f"
        fi
    done

    # Claude 個人設定の symlink を撤去する。
    # dotfiles 側の現状ではなく、~/.claude 配下で dotfiles を指している
    # 既存 symlink を動的に検出して外す（追加/削除後の張り直しでも取りこぼさない）。
    if [ -d ~/.claude ]; then
        find ~/.claude -type l | while read -r link; do
            if is_dotfiles_link "$link"; then
                unlink_file "$link"
            fi
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
