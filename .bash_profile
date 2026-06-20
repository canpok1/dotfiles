# Homebrew (Linux / Apple Silicon mac) を PATH に通す
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# workflow-scripts をどの git リポからでも呼べるよう PATH に追加
export PATH="$HOME/dotfiles/workflow-scripts:$PATH"

export GIT_PAGER="LESSCHARSET=utf-8 less"
if [ -e ~/.bash_profile_local ]; then
    source ~/.bash_profile_local
fi
source ~/.bashrc
