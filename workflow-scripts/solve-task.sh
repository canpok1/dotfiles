#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 対象はカレントの git リポジトリ
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Error: git リポジトリ内で実行してください" >&2; exit 1; }
WORKSPACE_DIR="$(pwd)"

# shellcheck source=workflow-scripts/lib.sh
source "${SCRIPT_DIR}/lib.sh"

PRINT_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p) PRINT_MODE=true; shift ;;
    *)
      if [[ -z "${TASK_ID:-}" ]] && [[ "$1" =~ ^[A-Za-z0-9]+$ ]]; then
        TASK_ID="$1"; shift
      else
        echo "Usage: $0 [-p] <task_id>" >&2; exit 1
      fi
      ;;
  esac
done

if [[ -z "${TASK_ID:-}" ]]; then
  echo "Error: task id is required" >&2
  echo "Usage: $0 [-p] <task_id>" >&2
  exit 1
fi

# Todoist 認証: 環境変数 TODOIST_API_TOKEN か `td auth login` のどちらかが必要
if [[ -z "${TODOIST_API_TOKEN:-}" ]] && ! command td auth status >/dev/null 2>&1; then
  echo "Error: Todoist が未認証です。TODOIST_API_TOKEN を設定するか td auth login を実行してください" >&2
  exit 1
fi

# td task のラベルは全置換のため、現在のラベルを読んで追加/除去する
set_labels() {
  local id="$1" labels="$2"
  if [[ -z "$labels" ]]; then
    td task update "$id" --labels false >/dev/null
  else
    td task update "$id" --labels "$labels" >/dev/null
  fi
}

add_label() {
  local id="$1" label="$2" labels
  labels=$(td task view "$id" --json | jq -r --arg l "$label" \
    '(.labels + [$l]) | unique | join(",")')
  set_labels "$id" "$labels"
}

remove_label() {
  local id="$1" label="$2" labels
  labels=$(td task view "$id" --json | jq -r --arg l "$label" \
    '[.labels[] | select(. != $l)] | join(",")')
  set_labels "$id" "$labels"
}

# ロックディレクトリの作成
LOCK_DIR="$WORKFLOW_LOCK_DIR"
mkdir -p "$LOCK_DIR"
lock_file="${LOCK_DIR}/${TASK_ID}"

# ファイルロックで重複実行を防止
exec 9>"$lock_file"
if ! flock -n 9; then
  echo "Task ${TASK_ID} is already being processed"
  exit 1
fi

# クリーンアップ: in-progressラベルを除去
cleanup() {
  echo "Removing in-progress label from ${TASK_ID}..."
  remove_label "$TASK_ID" "in-progress" 2>/dev/null || true
}
trap cleanup EXIT

# in-progressラベルを付与
echo "Adding in-progress label to ${TASK_ID}..."
add_label "$TASK_ID" "in-progress"

# mainブランチを最新化
cd "$WORKSPACE_DIR"
git checkout main
git pull origin main

# Claude実行（worktreeモード）
if [[ "$PRINT_MODE" == "true" ]]; then
  "${SCRIPT_DIR}/claude-stream.sh" --worktree "task-${TASK_ID}" --model sonnet -p "/solve-task ${TASK_ID}"
else
  claude --worktree "task-${TASK_ID}" --permission-mode auto --model sonnet "/solve-task ${TASK_ID}"
fi
