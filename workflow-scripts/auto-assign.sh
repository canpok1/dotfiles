#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 対象はカレントの git リポジトリ
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Error: git リポジトリ内で実行してください" >&2; exit 1; }
WORKSPACE_DIR="$(pwd)"

# shellcheck source=workflow-scripts/lib.sh
source "${SCRIPT_DIR}/lib.sh"

ASSIGN_COUNT=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c) ASSIGN_COUNT="$2"; shift 2 ;;
    *)
      if [[ -z "${MIN_QUEUE:-}" ]] && [[ "$1" =~ ^[0-9]+$ ]]; then
        MIN_QUEUE="$1"; shift
      else
        echo "Usage: $0 [-c count] <min-queue>" >&2; exit 1
      fi
      ;;
  esac
done

if [[ -z "${MIN_QUEUE:-}" ]]; then
  echo "Error: min-queue is required" >&2
  echo "Usage: $0 [-c count] <min-queue>" >&2
  exit 1
fi

if ! [[ "$ASSIGN_COUNT" =~ ^[0-9]+$ ]]; then
  echo "Error: count must be a number" >&2
  exit 1
fi

if [[ -z "${TODOIST_API_TOKEN:-}" ]]; then
  echo "Error: TODOIST_API_TOKEN is not set" >&2
  exit 1
fi

# 対象タスクの絞り込みフィルタ。~/.bash_profile_local 等で設定する。
: "${TODOIST_FILTER:?TODOIST_FILTER を設定してください}"

# 多重起動防止
LOCK_DIR="$WORKFLOW_LOCK_DIR"
mkdir -p "$LOCK_DIR"
lock_file="${LOCK_DIR}/auto-assign"

exec 9>"$lock_file"
if ! flock -n 9; then
  echo "auto-assign is already running"
  exit 1
fi

RUNNING=true
trap 'RUNNING=false; echo ""; echo "Shutting down..."; exit 0' SIGINT SIGTERM

echo "Watching queue in ${TODOIST_FILTER} (min-queue: ${MIN_QUEUE})..."

cd "$WORKSPACE_DIR"
PREV_STATE=""

while $RUNNING; do
  # assign-to-claudeラベル付きの未完了タスク数をカウント
  QUEUE_COUNT=$(td task list --filter "${TODOIST_FILTER} & @assign-to-claude" --json | jq '.results | length')

  if [[ "$QUEUE_COUNT" -ge "$MIN_QUEUE" ]]; then
    CURRENT_STATE="queue_sufficient"
    if [[ "$PREV_STATE" != "$CURRENT_STATE" ]]; then
      echo ""
      echo "Queue: ${QUEUE_COUNT} (>= ${MIN_QUEUE}), waiting..."
    else
      printf "."
    fi
  else
    # readyラベル付き + assign-to-claude/in-progress 未付与のタスクをカウント
    TASK_COUNT=$(td task list --filter "${TODOIST_FILTER} & @ready & !@assign-to-claude & !@in-progress" --json | jq '.results | length')

    if [[ "$TASK_COUNT" -eq 0 ]]; then
      CURRENT_STATE="no_tasks"
      if [[ "$PREV_STATE" != "$CURRENT_STATE" ]]; then
        echo ""
        echo "No tasks to assign, waiting..."
      else
        printf "."
      fi
    else
      CURRENT_STATE="assigning"
      echo ""
      echo "Queue: ${QUEUE_COUNT} (< ${MIN_QUEUE}), assigning..."

      "${SCRIPT_DIR}/claude-stream.sh" -p "/assign-tasks --count ${ASSIGN_COUNT}"
    fi
  fi

  PREV_STATE="$CURRENT_STATE"
  poll_sleep
done
