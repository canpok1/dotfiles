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
#   append.sh <project> <content>
#     project: [[project]] のリンクに使うプロジェクト名（通常は git リポジトリ名）
#     content: 見出しの下に入る本文
#
# 時刻は実行環境の TZ に関わらず常に JST (Asia/Tokyo) を使う。
# devcontainer / web はほぼ確実に UTC で、JST 09:00 = UTC 00:00 のため、
# TZ を固定しないと JST の朝9時より前の作業が前日のファイルに紛れ込む。

set -euo pipefail

VAULT_REMOTE_MATCH="canpok1/obsidian-vault"
VAULT_DIR_CANDIDATES=(
  "${OBSIDIAN_VAULT_DIR:-}"
  "$HOME/obsidian-vault"
  "$HOME/src/obsidian-vault"
)

usage() {
  echo "usage: $(basename "$0") <project> <content>" >&2
  exit 1
}

[ $# -eq 2 ] || usage
project="$1"
content="$2"

heading="## $(TZ=Asia/Tokyo date '+%F %H:%M') JST [[${project}]]"
entry="${heading}

${content}"

using_obsidian() {
  command -v obsidian >/dev/null 2>&1 && obsidian vault=obsidian-vault vault >/dev/null 2>&1
}

append_via_obsidian() {
  if ! obsidian vault=obsidian-vault file "file=${project}" >/dev/null 2>&1; then
    obsidian vault=obsidian-vault create "path=projects/${project}.md" \
      "content=# ${project}\n\n## 概要\n\n" >/dev/null
  fi

  local escaped="${entry//$'\n'/\\n}"
  obsidian vault=obsidian-vault daily:append "content=${escaped}\n" >/dev/null
}

# clone の実体を、環境変数指定 → 既定の候補パスの順に探す。
# .git があり、origin が vault を指しているものだけを採用する。
find_vault_dir() {
  local dir
  for dir in "${VAULT_DIR_CANDIDATES[@]}"; do
    [ -n "$dir" ] || continue
    [ -d "$dir/.git" ] || continue
    if git -C "$dir" remote get-url origin 2>/dev/null | grep -qF "$VAULT_REMOTE_MATCH"; then
      printf '%s' "$dir"
      return 0
    fi
  done
  return 1
}

ensure_project_note_git() {
  local vault_dir="$1" path="projects/${project}.md"
  [ -f "$vault_dir/$path" ] && return 0
  mkdir -p "$vault_dir/projects"
  printf '# %s\n\n## 概要\n\n' "$project" > "$vault_dir/$path"
  git -C "$vault_dir" add "$path"
}

# clone を他の用途（手動編集中など）と共用している可能性があるため、
# 開始時点で作業ツリーが汚れていなければ触らない。
# リトライ時は「開始時点はクリーンだった」という前提のもとで、
# 直前に自分が作った commit だけを reset --hard で取り消す(ユーザーの変更を巻き込まない)。
append_via_git() {
  local vault_dir="$1"

  if [ -n "$(git -C "$vault_dir" status --porcelain)" ]; then
    echo "work-log: ${vault_dir} に未コミットの変更があるため追記を中止しました" >&2
    return 1
  fi

  local date_jst path attempt=1 max_attempts=3 branch err_file
  date_jst="$(TZ=Asia/Tokyo date '+%F')"
  path="daily/${date_jst}.md"
  branch="$(git -C "$vault_dir" symbolic-ref --short HEAD)"
  err_file="$(mktemp)"
  trap 'rm -f "$err_file"' RETURN

  while :; do
    if ! git -C "$vault_dir" fetch origin "$branch" --quiet; then
      echo "work-log: git fetch に失敗しました" >&2
      return 1
    fi
    if ! git -C "$vault_dir" merge --ff-only "origin/${branch}" --quiet; then
      echo "work-log: ${vault_dir} がリモートと分岐しています。手動で解決してください" >&2
      return 1
    fi

    ensure_project_note_git "$vault_dir"
    mkdir -p "$vault_dir/daily"
    if [ -f "$vault_dir/$path" ]; then
      printf '\n%s\n' "$entry" >> "$vault_dir/$path"
    else
      printf '%s\n' "$entry" > "$vault_dir/$path"
    fi
    git -C "$vault_dir" add "$path"
    git -C "$vault_dir" commit --quiet -m "work-log: ${date_jst} (${project})"

    if git -C "$vault_dir" push origin "$branch" --quiet 2>"$err_file"; then
      return 0
    fi

    if [ "$attempt" -lt "$max_attempts" ] && grep -qE 'rejected|non-fast-forward|fetch first' "$err_file"; then
      git -C "$vault_dir" reset --hard --quiet HEAD~1
      attempt=$((attempt + 1))
      continue
    fi

    cat "$err_file" >&2
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
