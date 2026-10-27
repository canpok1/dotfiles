#!/bin/sh
# コンテナ（devcontainer / Claude Code on the web）向けの展開スクリプト。
# このスクリプトの1つ上を dotfiles の実体として扱う
# （~/dotfiles 以外へ clone しても、実行したクローンが正しくリンクされる）
DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd -P)" || exit 1
cd "$DOTFILES_DIR" || exit 1
. "$DOTFILES_DIR/container/lib.sh"

echo ---- dotfiles setup start ----
echo "make link (dotfiles: $DOTFILES_DIR)"

prune_dangling_claude_links

# 左がホームでの配置場所、右が参照先
link      ~/.vimrc                "$DOTFILES_DIR/tools/vim/vimrc"
link      ~/.claude/CLAUDE.md     "$DOTFILES_DIR/tools/claude/CLAUDE.md"
link      ~/.claude/settings.json "$DOTFILES_DIR/tools/claude/settings.json"
link      ~/.claude/statusline.sh "$DOTFILES_DIR/tools/claude/statusline.sh"
link_each ~/.claude/rules         "$DOTFILES_DIR/tools/claude/rules"
link_each ~/.claude/skills        "$DOTFILES_DIR/tools/claude/skills"
link_each ~/.claude/agents        "$DOTFILES_DIR/tools/claude/agents"

# シェル設定は symlink で置き換えず source 行を足す。
# devcontainer などが先に置いたファイルの内容を消さないため
source_in ~/.bashrc       "$DOTFILES_DIR/tools/shell/rc.sh"
source_in ~/.zshrc        "$DOTFILES_DIR/tools/shell/rc.sh"
source_in ~/.zprofile     "$DOTFILES_DIR/tools/shell/profile.sh"
source_in ~/.bash_profile "$DOTFILES_DIR/tools/shell/profile.sh" "$DOTFILES_DIR/tools/shell/rc.sh"

touch ~/.shell_local
echo ---- dotfiles setup end ----
