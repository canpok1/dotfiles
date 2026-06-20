---
name: read-task
description: Todoistタスクの内容（タイトル、本文、ラベル、コメント）を確認し、実装要件を整理する時に使うスキル。
argument-hint: "[task-id または検索キーワード]"
allowed-tools: mcp__todoist__find-tasks, mcp__todoist__fetch-object, mcp__todoist__find-comments
---

タスクの登録先・ラベル運用は `~/.claude/rules/task-management.md` に従う。

## 確認方法

- 引数がタスクIDの場合: `mcp__todoist__fetch-object` でタスクを取得する。
- 引数が検索キーワードの場合: `mcp__todoist__find-tasks`（`searchText`、必要に応じて `sectionId` で対象リポジトリ名のセクションに絞る）で対象タスクを特定する。
- コメントは `mcp__todoist__find-comments` で取得する。

## 注意点

- 確認した内容は、節目ごとに作業メモとして残すこと。要件の整理結果や判断のポイントを記録し、後続の作業で参照できるようにする。
- 取得結果が空だった場合は、タスク未取得のまま後続作業に進まないこと。ID指定なら `fetch-object`、検索なら `find-tasks` の条件（`searchText` / `sectionId` / `labels`）を見直して再取得してから内容を確認すること。
