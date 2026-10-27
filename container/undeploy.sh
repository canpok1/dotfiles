#!/bin/sh
# container/setup.sh で張ったものを外す。dotfiles を指す symlink と管理ブロックだけを外し、
# 既存ファイル本体は残す
DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd -P)" || exit 1
cd "$DOTFILES_DIR" || exit 1
. "$DOTFILES_DIR/container/lib.sh"

echo ---- dotfiles undeploy start ----
# dotfiles を指す symlink だけ撤去する（実体ファイルや未デプロイ時は触らない）
if [ -L ~/.vimrc ] && is_dotfiles_link ~/.vimrc; then
    unlink_file ~/.vimrc
fi

# シェル設定は管理ブロックのみ撤去する（既存ファイル本体は残す）
for f in ~/.bashrc ~/.zshrc ~/.zprofile ~/.bash_profile; do
    remove_managed_block "$f"
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
echo ---- dotfiles undeploy end ----
