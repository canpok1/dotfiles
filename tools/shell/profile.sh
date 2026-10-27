# bash / zsh 共通のログイン時設定（環境変数 / PATH）。
# .bash_profile と .zprofile から source する。

# 秘密・マシン固有の設定（非追跡）
if [ -e "$HOME/.shell_local" ]; then
    . "$HOME/.shell_local"
fi
