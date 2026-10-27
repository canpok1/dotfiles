#!/bin/sh
# コンテナ（devcontainer / Claude Code on the web）向けの展開スクリプト。
# このスクリプトの1つ上を dotfiles の実体として扱う
# （~/dotfiles 以外へ clone しても、実行したクローンが正しくリンクされる）
DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd -P)" || exit 1
cd "$DOTFILES_DIR" || exit 1

# 旧デフォルト配置。過去に ~/dotfiles から展開した symlink の撤去に使う
LEGACY_DOTFILES_DIR="$HOME/dotfiles"

MODE=deploy
while [ $# -gt 0 ]; do
    case "$1" in
        --undeploy) MODE=undeploy ;;
        *)
            echo "unknown option: $1" >&2
            echo "usage: container/setup.sh [--undeploy]" >&2
            exit 1
            ;;
    esac
    shift
done

if [ "$(uname)" != 'Linux' ]; then
    echo "this script is for containers (Linux). use mac/setup.sh on mac." >&2
    exit 1
fi

deploy() {
    echo "make link (dotfiles: $DOTFILES_DIR)"

    prune_dangling_claude_links

    # 左がホームでの配置場所、右が参照先
    link      ~/.vimrc                "$DOTFILES_DIR/tools/vim/vimrc"
    link      ~/.claude/CLAUDE.md     "$DOTFILES_DIR/tools/claude/CLAUDE.md"
    link      ~/.claude/settings.json "$DOTFILES_DIR/tools/claude/settings.json"
    link      ~/.claude/statusline.sh "$DOTFILES_DIR/tools/claude/statusline.sh"
    link_each ~/.claude/rules         "$DOTFILES_DIR/tools/claude/rules"
    link_each ~/.claude/skills        "$DOTFILES_DIR/tools/claude/skills"
    link_each ~/.claude/agents        "$DOTFILES_DIR/tools/claude/agents"

    # シェル設定は symlink で置き換えず source 行を足す。
    # devcontainer などが先に置いたファイルの内容を消さないため
    source_in ~/.bashrc       "$DOTFILES_DIR/tools/shell/rc.sh"
    source_in ~/.zshrc        "$DOTFILES_DIR/tools/shell/rc.sh"
    source_in ~/.zprofile     "$DOTFILES_DIR/tools/shell/profile.sh"
    source_in ~/.bash_profile "$DOTFILES_DIR/tools/shell/profile.sh" "$DOTFILES_DIR/tools/shell/rc.sh"

    touch ~/.shell_local
}

# ---- 以下は deploy / undeploy の補助 ----

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

# 実体があればバックアップしてから symlink を張る。ln とは引数の順が逆
link() {
    mkdir -p "$(dirname "$1")"
    backup_if_real "$1"
    ln -fnsv "$2" "$1"
}

# ディレクトリの中身を1件ずつ張る
link_each() {
    [ -d "$2" ] || return 0
    for _entry in "$2"/*; do
        [ -e "$_entry" ] || continue
        link "$1/$(basename "$_entry")" "$_entry"
    done
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

# 参照先が消えた symlink を撤去する。dotfiles からエントリを削除したとき
# （スキルを別リポジトリへ移した場合など）に、壊れたリンクが残り続けるのを防ぐ。
prune_dangling_claude_links() {
    [ -d ~/.claude ] || return 0

    find ~/.claude -type l | while read -r link; do
        [ -e "$link" ] && continue
        is_dotfiles_link "$link" && unlink_file "$link"
    done
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
# 活かしたまま dotfiles の共通設定（tools/shell/*.sh）を読み込める。
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

# 管理ブロックで DOTFILES_DIR を export してから、指定したファイルを順に source する。
# source される側は自分の位置を特定できないため export が要る
source_in() {
    _target="$1"; shift
    _body="export DOTFILES_DIR=\"$DOTFILES_DIR\""
    for _file in "$@"; do
        _body="$_body
. \"$_file\""
    done
    ensure_managed_block "$_target" "$_body"
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

case "$MODE" in
    undeploy)
        echo ---- dotfiles undeploy start ----
        undeploy
        echo ---- dotfiles undeploy end ----
        ;;
    *)
        echo ---- dotfiles setup start ----
        deploy
        echo ---- dotfiles setup end ----
        ;;
esac
