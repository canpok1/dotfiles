#!/usr/bin/env bash
# 作業記録を obsidian-vault のデイリーノートへ追記する。
#
# 追記できる手段を優先度順に試す。
#   1. obsidian CLI — ホストで Obsidian.app が起動していれば使える
#   2. obsidian-vault のローカル clone への git commit + push
#      — clone が見つからない場合は何もしない
#
# vault の clone を自動では作らない。記録するかどうかはユーザーが
# clone の有無で制御する（clone しておけば記録され、しなければ記録されない）。
#
# 使い方:
#   append.sh <project> <content> [branch]
#     project: [[project]] のリンクに使うプロジェクト名（通常は git リポジトリ名）
#     content: 見出しの下に入る本文
#     branch:  作業中のブランチ名（省略可）。指定すると見出しに (branch名) を付与する
#
# 時刻は実行環境の TZ に関わらず常に JST (Asia/Tokyo) を使う。
# devcontainer / web はほぼ確実に UTC で、JST 09:00 = UTC 00:00 のため、
# TZ を固定しないと JST の朝9時より前の作業が前日のファイルに紛れ込む。

set -euo pipefail

VAULT_REMOTE_MATCH="canpok1/obsidian-vault"
# vault は常にこのブランチへ直接反映する。ローカル clone が別ブランチを
# チェックアウトしていても（他タスクの作業ブランチ等）影響を受けない。
VAULT_TARGET_BRANCH="main"

usage() {
  echo "usage: $(basename "$0") <project> <content> [branch]" >&2
  exit 1
}

[ $# -eq 2 ] || [ $# -eq 3 ] || usage
project="$1"
content="$2"
branch="${3:-}"

heading="## $(TZ=Asia/Tokyo date '+%F %H:%M') JST [[${project}]]"
if [ -n "$branch" ]; then
  heading="${heading} (${branch})"
fi
entry="${heading}

${content}"

# プロジェクトノートのひな形。obsidian CLI 経由（改行はリテラル \n にエスケープ
# して渡す）と git 直接書き込み（実改行のまま書く）の両方から参照する。
project_note_body="# ${project}"$'\n\n'"## 概要"$'\n'

using_obsidian() {
  command -v obsidian >/dev/null 2>&1 && obsidian vault=obsidian-vault vault >/dev/null 2>&1
}

append_via_obsidian() {
  if ! obsidian vault=obsidian-vault file "file=${project}" >/dev/null 2>&1; then
    local body_escaped="${project_note_body//$'\n'/\\n}"
    obsidian vault=obsidian-vault create "path=projects/${project}.md" \
      "content=${body_escaped}\n" >/dev/null
  fi

  local escaped="${entry//$'\n'/\\n}"
  obsidian vault=obsidian-vault daily:append "content=${escaped}\n" >/dev/null
}

# clone の置き場所の候補を優先度順に出力する。
# $HOME はセッション種別によって実際の作業ディレクトリと一致しない
# ことがある（例: $HOME=/root だが各リポジトリは /home/user/ 配下）ため、
# 現在のプロジェクトの隣（兄弟ディレクトリ）も候補に含める。
vault_dir_candidates() {
  [ -n "${OBSIDIAN_VAULT_DIR:-}" ] && printf '%s\n' "$OBSIDIAN_VAULT_DIR"

  local proj_root
  if proj_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    printf '%s\n' "$(dirname "$proj_root")/obsidian-vault"
  fi

  printf '%s\n' "$HOME/obsidian-vault" "$HOME/src/obsidian-vault"
}

# 候補を順に見て、.git があり origin が vault を指しているものを採用する。
# 候補は重複しうる（例: プロジェクトの親ディレクトリ = $HOME）ため awk で去重する。
find_vault_dir() {
  local dir
  while IFS= read -r dir; do
    [ -d "$dir/.git" ] || continue
    if git -C "$dir" remote get-url origin 2>/dev/null | grep -qF "$VAULT_REMOTE_MATCH"; then
      printf '%s' "$dir"
      return 0
    fi
  done < <(vault_dir_candidates | awk '!seen[$0]++')
  return 1
}

# clone のチェックアウト状態やインデックス、作業ツリーには一切触れず、
# git plumbing コマンドだけで origin/<VAULT_TARGET_BRANCH> の先に
# コミットを作って push する。他タスクの作業ブランチと clone を共有していても
# 干渉しない。
append_via_git() {
  local vault_dir="$1"

  local date_jst daily_path proj_path attempt=1 max_attempts=3
  date_jst="$(TZ=Asia/Tokyo date '+%F')"
  daily_path="daily/${date_jst}.md"
  proj_path="projects/${project}.md"

  while :; do
    if ! git -C "$vault_dir" fetch origin "$VAULT_TARGET_BRANCH" --quiet; then
      echo "work-log: git fetch に失敗しました" >&2
      return 1
    fi

    local base_sha
    base_sha="$(git -C "$vault_dir" rev-parse "origin/${VAULT_TARGET_BRANCH}")"

    local daily_content
    if daily_content="$(git -C "$vault_dir" show "${base_sha}:${daily_path}" 2>/dev/null)"; then
      daily_content="${daily_content}"$'\n\n'"${entry}"
    else
      daily_content="${entry}"
    fi

    local tmp_index
    tmp_index="$(mktemp)"
    GIT_INDEX_FILE="$tmp_index" git -C "$vault_dir" read-tree "$base_sha"

    local daily_blob
    daily_blob="$(printf '%s\n' "$daily_content" | git -C "$vault_dir" hash-object -w --stdin)"
    GIT_INDEX_FILE="$tmp_index" git -C "$vault_dir" update-index --add --cacheinfo "100644,${daily_blob},${daily_path}"

    if ! git -C "$vault_dir" cat-file -e "${base_sha}:${proj_path}" 2>/dev/null; then
      local proj_blob
      proj_blob="$(printf '%s' "$project_note_body" | git -C "$vault_dir" hash-object -w --stdin)"
      GIT_INDEX_FILE="$tmp_index" git -C "$vault_dir" update-index --add --cacheinfo "100644,${proj_blob},${proj_path}"
    fi

    local new_tree new_commit
    new_tree="$(GIT_INDEX_FILE="$tmp_index" git -C "$vault_dir" write-tree)"
    rm -f "$tmp_index"

    new_commit="$(git -C "$vault_dir" commit-tree "$new_tree" -p "$base_sha" -m "work-log: ${date_jst} (${project})")"

    local push_err
    push_err="$(git -C "$vault_dir" push origin "${new_commit}:refs/heads/${VAULT_TARGET_BRANCH}" --quiet 2>&1)" && return 0

    if [ "$attempt" -lt "$max_attempts" ] && printf '%s' "$push_err" | grep -qE 'rejected|non-fast-forward|fetch first|stale info'; then
      attempt=$((attempt + 1))
      continue
    fi

    printf '%s\n' "$push_err" >&2
    return 1
  done
}

if using_obsidian; then
  append_via_obsidian
  exit 0
fi

if vault_dir="$(find_vault_dir)"; then
  append_via_git "$vault_dir"
  exit $?
fi

echo "work-log: obsidian-vault の clone が見つからないため、追記をスキップしました" >&2
exit 0
