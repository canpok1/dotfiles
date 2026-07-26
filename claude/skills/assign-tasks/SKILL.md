---
name: assign-tasks
description: dev プロジェクト・対象リポジトリ名セクションのreadyタスクを優先度順に評価し、指定件数にassign-to-claudeラベルを付与するスキル
allowed-tools: Bash, Read, Grep, Glob, Agent, mcp__todoist__find-tasks, mcp__todoist__update-tasks
user-invocable: true
argument-hint: "[--count N]"
---

タスクの登録先・ラベル運用はタスク管理ルールに従う。

## 手順

1. 対象リポジトリ名のセクションから、未完了かつ `ready` ラベル付きのタスクを取得する。
2. `assign-to-claude` または `in-progress` ラベルが付いているタスクを除外する（除外したタスクはターミナルへログ出力する）。
3. 残りのタスクを優先度基準（緊急度・価値・実現性・前提の妥当性など）に従って優先順位付けする。優先度評価用のエージェント／スキルが利用できれば活用してよい。
4. 上位N件（`$ARGUMENTS` の `--count` で指定、デフォルト: 2件）に `assign-to-claude` ラベルを付与する。

## 出力

- 除外したタスク: ID、タイトル、除外理由（ターミナルのみ）
- アサインしたタスク: ID、タイトル、判定根拠（ターミナルのみ）

## 制約

- タスクへのコメント投稿は禁止
- 行う操作はタスクの取得とラベル更新のみ（コメント・完了・削除などはしない）
