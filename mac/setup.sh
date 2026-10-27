#!/bin/sh
# mac 向けのセットアップ。設定ファイルの展開とパッケージの導入を home-manager に任せる
# （docs/adr/0016）。何度実行してもよい。
# このスクリプトの1つ上を dotfiles の実体として扱う（~/dotfiles 以外へ clone してもよい）
DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd -P)" || exit 1
export DOTFILES_DIR

PROFILE_ARG=""
while [ $# -gt 0 ]; do
    case "$1" in
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
            echo "usage: mac/setup.sh [--profile <private|work>]" >&2
            exit 1
            ;;
    esac
    shift
done

if [ "$(uname)" != 'Darwin' ]; then
    echo "this script is for mac. use container/setup.sh in containers." >&2
    exit 1
fi

# --profile 引数 > DOTFILES_PROFILE 環境変数 > ~/.dotfiles-profile > private
PROFILE="$PROFILE_ARG"
[ -n "$PROFILE" ] || PROFILE="${DOTFILES_PROFILE:-}"
if [ -z "$PROFILE" ] && [ -f "$HOME/.dotfiles-profile" ]; then
    PROFILE="$(head -n 1 "$HOME/.dotfiles-profile" | tr -d '[:space:]')"
fi
[ -n "$PROFILE" ] || PROFILE=private
case "$PROFILE" in
    private | work) echo "profile: $PROFILE" ;;
    *)
        # 打ち間違いのまま私用設定が仕事環境へ入るのを防ぐため、既定へ倒さず止める
        echo "unknown profile: $PROFILE (available: private work)" >&2
        exit 1
        ;;
esac

if ! command -v nix >/dev/null 2>&1; then
    curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes || exit 1
    # 導入直後のこのシェルには PATH が通っていない
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

if ! command -v vox-actor >/dev/null 2>&1; then
    curl -fsSL https://github.com/canpok1/vox-actor/releases/latest/download/install.sh | bash
fi

# 旧 setup.sh が張った dotfiles 直指しの symlink を外す。残っていると home-manager が衝突で止まる。
# home-manager が張ったものは Nix の保管場所を経由するため、ここには掛からない
for link in ~/.vimrc $(find ~/.claude -type l 2>/dev/null); do
    [ -L "$link" ] || continue
    case "$(readlink "$link")" in
        "$DOTFILES_DIR"/* | "$HOME/dotfiles"/*) unlink "$link" && echo "unlink legacy $link" ;;
    esac
done

# 既存のシェル設定などは .hm-bak へ退避してから置き換える。
# flakes 無効のまま入っている Nix でも動くよう、機能をコマンドごとに有効にする
nix --extra-experimental-features 'nix-command flakes' \
    run "$DOTFILES_DIR/mac" -- \
    switch --flake "$DOTFILES_DIR/mac#$PROFILE" --impure -b hm-bak
