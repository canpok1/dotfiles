# git のプロンプト/補完を環境に応じて読み込む（存在するものだけ source する）
_source_git_helper() {
    local d
    for d in "${HOMEBREW_PREFIX:-}/etc/bash_completion.d" \
             "${HOMEBREW_PREFIX:-}/share/git-core/contrib/completion" \
             /usr/local/etc/bash_completion.d \
             /opt/homebrew/etc/bash_completion.d \
             /usr/share/git-core/contrib/completion; do
        if [ -r "$d/$1" ]; then
            source "$d/$1"
            return
        fi
    done
}
_source_git_helper git-prompt.sh
_source_git_helper git-completion.bash
unset -f _source_git_helper

GIT_PS1_SHOWDIRTYSTATE=true
if type __git_ps1 >/dev/null 2>&1; then
    export PS1='\h\[\033[00m\]:\W\[\033[31m\]$(__git_ps1 [%s])\[\033[00m\]\$ '
else
    export PS1='\h:\W\$ '
fi

alias memo='vim ~/memo.txt'
alias todo='vim ~/todo.txt'
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

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
