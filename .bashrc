source /usr/local/etc/bash_completion.d/git-prompt.sh
source /usr/local/etc/bash_completion.d/git-completion.bash

GIT_PS1_SHOWDIRTYSTATE=true
export PS1='\h\[\033[00m\]:\W\[\033[31m\]$(__git_ps1 [%s])\[\033[00m\]\$ '

if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

alias ctags='/usr/local/Cellar/ctags/5.8_1/bin/ctags'
alias memo='vim ~/memo.md'
alias todo='vim ~/todo.txt'

case "${OSTYPE}" in
darwin*)
  alias ls="ls -G"
  alias ll="ls -lG"
  alias la="ls -laG"
  ;;
linux*)
  alias ls="ls --color"
  alias ll="ls -l --color"
  alias la="ls -la --color"
  ;;
esac
