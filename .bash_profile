export PATH="/usr/local/Cellar/git/2.16.2/bin:$PATH"
export PATH="$HOME/.ndenv/bin:$PATH"
export PATH="$HOME/.yarn/bin:$PATH"
export PATH="$HOME/code/go/bin:$PATH"
export GOPATH="$HOME/code/go"

# for goenv
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"

export GIT_PAGER="LESSCHARSET=utf-8 less"
if [ -e ~/.bash_profile_local ]; then
    source ~/.bash_profile_local
fi
source ~/.bashrc
