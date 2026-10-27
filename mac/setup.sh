#!/bin/sh
# mac 向けのセットアップ。設定ファイルの展開とパッケージの導入を home-manager に任せる
# （docs/adr/0016）。何度実行してもよい。
# このスクリプトの1つ上を dotfiles の実体として扱う（~/dotfiles 以外へ clone してもよい）
DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd -P)" || exit 1
export DOTFILES_DIR

if [ $# -gt 0 ]; then
    echo "usage: mac/setup.sh" >&2
    exit 1
fi

if [ "$(uname)" != 'Darwin' ]; then
    echo "this script is for mac. use container/setup.sh in containers." >&2
    exit 1
fi

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
    switch --flake "$DOTFILES_DIR/mac#default" --impure -b hm-bak
