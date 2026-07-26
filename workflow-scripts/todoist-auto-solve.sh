#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 対象はカレントの git リポジトリ
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Error: git リポジトリ内で実行してください" >&2; exit 1; }

# shellcheck source=workflow-scripts/todoist-lib.sh
source "${SCRIPT_DIR}/todoist-lib.sh"

if [[ $# -gt 0 ]]; then
  echo "Usage: $0" >&2; exit 1
fi

# Todoist 認証: 環境変数 TODOIST_API_TOKEN か `td auth login` のどちらかが必要
if [[ -z "${TODOIST_API_TOKEN:-}" ]] && ! command td auth status >/dev/null 2>&1; then
  echo "Error: Todoist が未認証です。TODOIST_API_TOKEN を設定するか td auth login を実行してください" >&2
  exit 1
fi

# 対象タスクの絞り込みフィルタ。~/.bash_profile_local 等で設定する。
# 対象タスクの絞り込みフィルタ: プロジェクト dev / セクション = リポジトリ名
REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
TODOIST_FILTER="#dev & /${REPO_NAME}"

RUNNING=true
trap 'RUNNING=false; echo ""; echo "Shutting down..."; exit 0' SIGINT SIGTERM

echo "Watching queued tasks in ${TODOIST_FILTER}..."

while $RUNNING; do
  # assign-to-claudeラベル付き + in-progress未付与のタスクを検索（作成が古い順に先頭1件）
  # addedAt は --full 指定時のみ JSON に含まれるため付与する
  TASK=$(td task list --filter "${TODOIST_FILTER} & @assign-to-claude & !@in-progress" --json --full \
    | jq -c '.results | sort_by(.addedAt) | first // empty')

  if [[ -n "$TASK" ]]; then
    TASK_ID=$(echo "$TASK" | jq -r '.id')
    TASK_TITLE=$(echo "$TASK" | jq -r '.content')
    echo ""
    echo "${TASK_ID} ${TASK_TITLE}"
    "${SCRIPT_DIR}/todoist-solve-task.sh" -p "$TASK_ID"
  else
    printf "."
  fi

  poll_sleep
done
