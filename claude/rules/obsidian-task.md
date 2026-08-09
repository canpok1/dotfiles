---
paths:
  - "tasks/**/*.md"
---

# Obsidian 利用時のタスク管理ルール

## 適用条件

本ルールは、タスク（フォローアップ・バックログ・別マシン/別環境への作業引き継ぎ等）の保存に **Obsidian vault（`canpok1/obsidian-vault` リポジトリ）の `tasks/` を使う場合にのみ適用する**。

- vault への実際の書き込み方法（Obsidian CLI・ローカル clone への git 操作など）は本ルールの対象外。obsidian-vault リポジトリの `.claude/CLAUDE.md` を参照する
- 本ルールはタスクファイルの保存先・命名・構成のみを扱う

## 保存先

- パス: `tasks/<repo名>/<ファイル名>.md`
- `<repo名>` は保存元のリポジトリ名（`basename "$(git rev-parse --show-toplevel)"` で特定する）
- **プロジェクトごとにディレクトリを分ける。** Obsidian を使わず GitHub のファイルブラウザで見るときに、どのプロジェクトのタスクか一目で分かるようにするため
- ディレクトリ名は ASCII のみを使う。全角文字は使わない
- 複数プロジェクトにまたがる場合は主となるプロジェクトの配下に置き、本文で他方へリンクする

## ファイル名

`YYYYMMDDHHMMSS-<slug>.md`

- 先頭の日時は作成時刻を秒単位まで区切り無しで入れる（`date '+%Y%m%d%H%M%S'`）。作成順をファイル名だけで判別できるようにするため

## frontmatter

`project` / `status` / `created` を持たせる。`status` は `todo` / `doing` / `done`。

```yaml
---
project: dotfiles
status: todo
created: 2026-08-08
---
```

- **ステータスが変わってもファイルを移動しない。** frontmatter を書き換える。コンテナから GitHub API 等で更新する際に削除+作成にならないため
- frontmatter の `project` はディレクトリ名と重複するが、ファイル単体で自己記述的にするため残す

## タスクの探し方

閲覧手段は用途で分ける。どちらもファイルを移動しないので、タスク間の参照は壊れない。

- **人間**: Obsidian で `tasks/tasks.base` を開く。「未完了」（`status != done` を `status` でグループ化）と「すべて」（`project` でグループ化）の2ビューがある
- **Claude Code**: vault のルートで `rg` を使う
    - 未着手の抽出: `rg -l '^status: todo' tasks/`
    - ステータス付き一覧: `rg -n '^status:' tasks/*/*.md`

**ステータスの正本は frontmatter の `status` であり、ディレクトリでは表現しない。** `tasks/<repo名>/<status>/` のようにディレクトリで持つ案は却下済み（`docs/adr/0004-task-status-in-frontmatter-not-directory.md`）。

## 本文の書き方

- 冒頭に `[[プロジェクト名]]` を書き、vault 側のプロジェクトノートのバックリンクに集約させる
- **この会話を知らない別環境の Claude Code が単独で実行できる粒度で書く。** 背景・決定事項・未確認点・受け入れ条件を含める
