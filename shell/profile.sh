# bash / zsh 共通のログイン時設定（環境変数 / PATH）。
# .bash_profile と .zprofile から source する。

# Homebrew (Linux / Apple Silicon mac) を PATH に通す
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# workflow-scripts をどの git リポからでも呼べるよう PATH に追加
export PATH="$HOME/dotfiles/workflow-scripts:$PATH"

# 秘密・マシン固有の設定（非追跡）
if [ -e "$HOME/.shell_local" ]; then
    . "$HOME/.shell_local"
fi
