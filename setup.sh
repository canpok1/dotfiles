#!/bin/sh
# このスクリプトが置かれているディレクトリを dotfiles の実体として扱う
# （~/dotfiles 以外へ clone しても、実行したクローンが正しくリンクされる）
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd -P)" || exit 1
cd "$DOTFILES_DIR" || exit 1

# 旧デフォルト配置。過去に ~/dotfiles から展開した symlink の撤去に使う
LEGACY_DOTFILES_DIR="$HOME/dotfiles"

MODE=deploy
PROFILE_ARG=""
while [ $# -gt 0 ]; do
    case "$1" in
        --undeploy) MODE=undeploy ;;
        --init) MODE=init ;;
        --profile)
            shift
            if [ $# -eq 0 ]; then
                echo "--profile requires a profile name" >&2
                exit 1
            fi
            PROFILE_ARG="$1"
            ;;
        *)
            echo "unknown option: $1" >&2
            echo "usage: setup.sh [--init | --undeploy] [--profile <name>]" >&2
            exit 1
            ;;
    esac
    shift
done

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

# symlink の参照先を dotfiles ルートからの相対パスへ変換する。
# dotfiles 配下でなければ何も出力しない。
dotfiles_relpath() {
    case "$1" in
        "$DOTFILES_DIR"/*) printf '%s' "${1#$DOTFILES_DIR/}" ;;
        "$LEGACY_DOTFILES_DIR"/*) printf '%s' "${1#$LEGACY_DOTFILES_DIR/}" ;;
    esac
}

# 絞り込みを行わない既定プロファイル。conf を持たない予約名として扱う
PROFILE_DEFAULT=private

# profiles/*.conf から選択可能なプロファイル名を列挙する（エラーメッセージ用）
list_profiles() {
    for _c in "$DOTFILES_DIR"/profiles/*.conf; do
        [ -e "$_c" ] || continue
        _n="$(basename "$_c")"
        printf '%s ' "${_n%.conf}"
    done
}

# 展開するプロファイル名。優先順は
# --profile 引数 > DOTFILES_PROFILE 環境変数 > ~/.dotfiles-profile > private。
resolve_profile() {
    if [ -n "$PROFILE_ARG" ]; then
        printf '%s' "$PROFILE_ARG"
        return
    fi
    if [ -n "${DOTFILES_PROFILE:-}" ]; then
        printf '%s' "$DOTFILES_PROFILE"
        return
    fi
    if [ -f "$HOME/.dotfiles-profile" ]; then
        _p="$(head -n 1 "$HOME/.dotfiles-profile" | tr -d '[:space:]')"
        if [ -n "$_p" ]; then
            printf '%s' "$_p"
            return
        fi
    fi
    printf '%s' "$PROFILE_DEFAULT"
}

# プロファイルの許可リスト（改行区切り）。PROFILE_FILTERED=0 のときは絞り込まない。
PROFILE_NAME=""
PROFILE_FILTERED=0
PROFILE_ALLOW=""

# profiles/<プロファイル名>.conf を読み込む。
# private は「絞り込みなし＝全件展開」を表す予約名で、conf を持たない。
load_profile() {
    PROFILE_NAME="$(resolve_profile)"
    _conf="$DOTFILES_DIR/profiles/$PROFILE_NAME.conf"

    if [ "$PROFILE_NAME" = "$PROFILE_DEFAULT" ]; then
        echo "profile: $PROFILE_NAME (deploy all)"
        return 0
    fi

    # private 以外で conf が無いのは名前の打ち間違いの可能性が高い。
    # 黙って全件展開すると仕事環境へ私用設定が入るため、ここで中断する。
    if [ ! -f "$_conf" ]; then
        echo "unknown profile: $PROFILE_NAME (profiles/$PROFILE_NAME.conf not found)" >&2
        echo "available profiles: $PROFILE_DEFAULT $(list_profiles)" >&2
        exit 1
    fi

    PROFILE_FILTERED=1
    # コメント行・空行を落とし、前後の空白と行末の / を取り除く
    PROFILE_ALLOW="$(
        grep -v '^[[:space:]]*#' "$_conf" \
            | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's#/$##' \
            | grep -v '^$'
    )"
    echo "profile: $PROFILE_NAME (profiles/$PROFILE_NAME.conf)"

    # 実体の無いエントリは書き間違い・リネーム漏れの可能性が高いので知らせる。
    # 展開そのものは続行する（他のエントリまで巻き込まない）。
    printf '%s\n' "$PROFILE_ALLOW" | while read -r entry; do
        [ -n "$entry" ] || continue
        [ -e "$DOTFILES_DIR/$entry" ] || \
            echo "warning: $entry not found (profiles/$PROFILE_NAME.conf)" >&2
    done
}

# リポジトリルートからの相対パスが、現在のプロファイルで展開対象かを判定する
is_allowed() {
    [ "$PROFILE_FILTERED" -eq 1 ] || return 0
    printf '%s\n' "$PROFILE_ALLOW" | grep -qxF "$1"
}

# 展開対象であれば symlink を張る（$1 は dotfiles 配下の絶対パス）
link_if_allowed() {
    if is_allowed "$(dotfiles_relpath "$1")"; then
        link_file "$1" "$2"
    fi
}

# プロファイルで除外された設定が過去の展開で残っていれば撤去する。
# プロファイル指定を忘れて全件展開した後に指定し直した場合や、
# conf からエントリを削った場合に、古い symlink が残り続けるのを防ぐ。
prune_disallowed_claude_links() {
    [ "$PROFILE_FILTERED" -eq 1 ] || return 0
    [ -d ~/.claude ] || return 0

    find ~/.claude -type l | while read -r link; do
        _rel="$(dotfiles_relpath "$(readlink "$link")")"
        [ -n "$_rel" ] || continue
        is_allowed "$_rel" || unlink_file "$link"
    done
}

# 参照先が消えた symlink を撤去する。dotfiles からエントリを削除したとき
# （スキルを別リポジトリへ移した場合など）に、壊れたリンクが残り続けるのを防ぐ。
# プロファイルの絞り込みとは独立した後始末なので、指定の有無に関わらず行う。
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
    load_profile

    # _vimrc とシェル設定はプロファイルの絞り込み対象外（常に展開する）
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

    # Claude 個人設定（CLAUDE.md / settings.json / statusline.sh / agents / skills / rules）を
    # ~/.claude へ展開する。ここはプロファイルの絞り込み対象。
    mkdir -p ~/.claude/skills ~/.claude/agents ~/.claude/rules
    prune_dangling_claude_links
    prune_disallowed_claude_links
    link_if_allowed "$DOTFILES_DIR/claude/CLAUDE.md" ~/.claude/CLAUDE.md
    link_if_allowed "$DOTFILES_DIR/claude/settings.json" ~/.claude/settings.json
    link_if_allowed "$DOTFILES_DIR/claude/statusline.sh" ~/.claude/statusline.sh
    for agent in "$DOTFILES_DIR"/claude/agents/*.md; do
        [ -e "$agent" ] || continue
        link_if_allowed "$agent" ~/.claude/agents/"$(basename "$agent")"
    done
    for skill_dir in "$DOTFILES_DIR"/claude/skills/*/; do
        [ -e "$skill_dir" ] || continue
        link_if_allowed "${skill_dir%/}" ~/.claude/skills/"$(basename "$skill_dir")"
    done
    for rule in "$DOTFILES_DIR"/claude/rules/*; do
        [ -e "$rule" ] || continue
        link_if_allowed "$rule" ~/.claude/rules/"$(basename "$rule")"
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

case "$MODE" in
    undeploy)
        # 撤去は展開時のプロファイルを問わない（dotfiles を指す symlink を全て外す）
        echo ---- dotfiles undeploy start ----
        undeploy
        echo ---- dotfiles undeploy end ----
        ;;
    init)
        echo ---- initialize start ----
        deploy
        initialize
        echo ---- initialize end ----
        ;;
    *)
        echo ---- dotfiles setup start ----
        deploy
        echo ---- dotfiles setup end ----
        ;;
esac
