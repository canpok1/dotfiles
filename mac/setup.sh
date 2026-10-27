#!/bin/sh
# mac 向けのセットアップ。設定ファイルの展開とパッケージの導入を home-manager に任せる
# （docs/adr/0016）。Nix（flakes 有効）は導入済みの前提。何度実行してもよい。
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

# home-manager は flake 経由で起動する（事前の導入は不要）。
# 既存のシェル設定などは .hm-bak へ退避してから置き換える
nix run "$DOTFILES_DIR/mac#home-manager" -- switch --flake "$DOTFILES_DIR/mac#default" --impure -b hm-bak
