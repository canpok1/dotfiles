#!/usr/bin/env bash
# 作業記録を obsidian-vault のデイリーノートへ追記する。
#
# devcontainer / Claude Code on the web（環境1・2）では起動中の Obsidian
# 本体に触れないため、GitHub Contents API（gh api）で daily/*.md を直接
# 読み書きする。vault の clone は作らない（陳腐化と手動 fetch の管理を
# 避けるため）。ホスト直（環境3）では obsidian CLI 経由で追記する。
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

VAULT_REPO="canpok1/obsidian-vault"

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

# obsidian CLI が使えれば環境3（ホスト直）とみなす。
# 使えなければ環境1・2（devcontainer / web）とみなし、gh api にフォールバックする。
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

gh_content_exists() {
  gh api "repos/${VAULT_REPO}/contents/$1" >/dev/null 2>&1
}

ensure_project_note_gh() {
  local path="projects/${project}.md"
  gh_content_exists "$path" && return 0

  local body b64
  body="$(printf '# %s\n\n## 概要\n\n' "$project")"
  b64="$(printf '%s' "$body" | base64 | tr -d '\n')"
  gh api -X PUT "repos/${VAULT_REPO}/contents/${path}" \
    -f message="work-log: create project note (${project})" \
    -f content="$b64" >/dev/null
}

# GitHub Contents API は更新時に既存ファイルの SHA を要求する楽観ロックを持つ。
# 複数環境から同じ日報ファイルへ同時に追記しうるため、409/422（SHA不一致）を
# 検知したら GET からやり直す。
append_via_gh_api() {
  ensure_project_note_gh

  local date_jst path attempt=1 max_attempts=3
  date_jst="$(TZ=Asia/Tokyo date '+%F')"
  path="daily/${date_jst}.md"

  while :; do
    local get_resp sha new_content b64 err

    if get_resp="$(gh api "repos/${VAULT_REPO}/contents/${path}" 2>/dev/null)"; then
      sha="$(printf '%s' "$get_resp" | jq -r '.sha')"
      new_content="$(printf '%s' "$get_resp" | jq -r '.content' | base64 -d)"$'\n\n'"${entry}"$'\n'
    else
      sha=""
      new_content="${entry}"$'\n'
    fi

    b64="$(printf '%s' "$new_content" | base64 | tr -d '\n')"

    local args=(-X PUT "repos/${VAULT_REPO}/contents/${path}"
      -f message="work-log: ${date_jst}"
      -f content="$b64")
    [ -n "$sha" ] && args+=(-f sha="$sha")

    if err="$(gh api "${args[@]}" 2>&1 1>/dev/null)"; then
      return 0
    fi

    if [ "$attempt" -lt "$max_attempts" ] && printf '%s' "$err" | grep -qE 'HTTP 409|HTTP 422'; then
      attempt=$((attempt + 1))
      continue
    fi

    printf '%s\n' "$err" >&2
    return 1
  done
}

if using_obsidian; then
  append_via_obsidian
else
  append_via_gh_api
fi
