# bash / zsh 共通のログイン時設定（環境変数 / PATH）。
# .bash_profile と .zprofile から source する。

# workflow-scripts をどの git リポからでも呼べるよう PATH の末尾に追加する
# （末尾にすることで既存コマンドを上書きしない）。
# DOTFILES_DIR は setup.sh が生成する管理ブロックで export される。
# 未設定の環境（管理ブロックが古い場合など）では従来の配置にフォールバックする。
export PATH="$PATH:${DOTFILES_DIR:-$HOME/dotfiles}/workflow-scripts"

# 秘密・マシン固有の設定（非追跡）
if [ -e "$HOME/.shell_local" ]; then
    . "$HOME/.shell_local"
fi
