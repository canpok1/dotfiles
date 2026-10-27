# bash / zsh 共通の対話シェル設定（エイリアス）。
# .bashrc と .zshrc から source する。

alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

case "$(uname)" in
Darwin)
  alias ls="ls -G"
  alias ll="ls -lG"
  alias la="ls -laG"
  ;;
Linux)
  alias ls="ls --color"
  alias ll="ls -l --color"
  alias la="ls -la --color"
  ;;
esac
