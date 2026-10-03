# 0011. タスク管理の保存先から Todoist を外す

- ステータス: 採用
- 日付: 2026-10-03

## コンテキスト

タスク管理の保存先として Todoist と brain リポジトリ（`tasks/`）の2つを持っていた。Todoist 向けには専用スキル（`todoist-assign-tasks` / `todoist-solve-task`）、エージェント `task-assigner`、巡回スクリプト（`workflow-scripts/todoist-*.sh`）、ルール `claude/rules/todoist.md`、`setup.sh` での Todoist CLI 導入がある。

Todoist は使わなくなった。

## 決定

**Todoist 前提の設定を一式削除し、タスクの保存先は brain の `tasks/` だけにする。**

- 上記のスキル・エージェント・スクリプト・ルール・CLI 導入、`discuss` / `refine` の Todoist 用ツール許可、README の記述を除去する
- `workflow-scripts/claude-stream.sh` は Todoist に依存しない汎用ラッパーのため残す
- 過去の ADR（0002・0005〜0008）の Todoist への言及は当時の経緯として残し、書き換えない

## 結果

良い影響: 使わない設定が展開されなくなり、存在しない保存先を前提にした手順・参照が残らない。

悪い影響: Todoist を再び使う場合は、git 履歴から復元する必要がある。

## 検討した代替案

- **スキルだけ削除する**: 変更は最小だが、巡回スクリプトが存在しないスキルを呼ぶ状態になり、ルールも使われないまま残るため却下
