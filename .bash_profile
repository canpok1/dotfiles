export PATH="/usr/local/Cellar/git/2.16.2/bin:$PATH"
export PATH="$HOME/.ndenv/bin:$PATH"
export PATH="$HOME/.yarn/bin:$PATH"
export PATH="$HOME/code/go/bin:$PATH"
export GOPATH="$HOME/code/go"

# for goenv
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"

# Homebrew (Linux / Apple Silicon mac) を PATH に通す
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# workflow-scripts をどの git リポからでも呼べるよう PATH に追加
export PATH="$HOME/dotfiles/workflow-scripts:$PATH"

# 各種バージョンマネージャの初期化（PATH/シムを設定）
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
if which ndenv > /dev/null; then eval "$(ndenv init -)"; fi
if which goenv > /dev/null; then eval "$(goenv init -)"; fi

export GIT_PAGER="LESSCHARSET=utf-8 less"
if [ -e ~/.bash_profile_local ]; then
    source ~/.bash_profile_local
fi
source ~/.bashrc
