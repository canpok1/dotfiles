# 0002. obsidian-task-rule-in-dotfiles

- ステータス: 採用
- 日付: 2026-08-08

## コンテキスト

obsidian-vault リポジトリの `.claude/CLAUDE.md` に、他リポジトリでの作業を別マシン/別環境へ引き継ぐための「タスクファイル」の書き方（保存先パス・ファイル命名規則・frontmatter仕様・書き方の指針）が定義されていた。この規約は obsidian-vault 自身の中で完結する内容ではなく、実際にはタスクを作成する側（dotfiles を都度利用する、obsidian-vault 以外の各プロジェクトでの作業セッション）が読んで従う必要がある。

dotfiles 側には既に `claude/rules/todoist.md` という前例があり、「特定の外部システム（Todoist）をタスク管理に使う場合にのみ適用する」運用ルールを、適用条件を明記した上で `~/.claude/rules/` へ展開し全プロジェクト共通で読み込む構成を取っている。dotfiles はユーザーが開発時に毎回利用する前提であり、Obsidian vault へのタスク保存規約も同様の構成にできる。

## 決定

タスクファイルの書き方（保存先・命名規則・frontmatter・書き方の指針）を、dotfiles の `claude/rules/obsidian-task.md` に新規ルールとして移動する。todoist.md と同様に適用条件を明記し、`paths: ["tasks/**/*.md"]` を付与して該当ファイルを扱うときにのみ読み込まれるようにする。

obsidian-vault 側の `.claude/CLAUDE.md` からは移動した内容を削除し、「詳細は dotfiles の `claude/rules/obsidian-task.md` を参照」という参照のみを残す。vault への実際の書き込み方法（Obsidian CLI・ローカル clone への git 操作、git 運用）は obsidian-vault 固有の操作知識であり、本ルールの対象外として obsidian-vault 側に残す。

## 結果

良い影響: タスクの書き方の正本が1箇所（dotfiles）に一本化され、二重管理・将来の記述ズレを防げる。dotfiles を経由するあらゆるプロジェクトから、obsidian-vault の CLAUDE.md を読みに行かなくてもタスクファイルの書き方が分かる。todoist.md と同じ構成のため学習コストが低い。

悪い影響: obsidian-vault リポジトリを GitHub 上で単体閲覧する場合（dotfiles のルールを読める環境にいない場合）、タスクの書き方の詳細を追うには dotfiles 側を別途参照する必要がある。

## 検討した代替案

- **命名規則だけを dotfiles へ移し、frontmatter仕様・書き方の指針は obsidian-vault に残す**: 分割すると「tasksの書き方」という一体の規約が2箇所に分断され、参照時にどちらも見る必要が生じるため却下。
- **obsidian-vault側にも要点を残す（重複許容）**: obsidian-vault単体での自己完結性は保てるが、将来どちらかだけを更新して内容がズレるリスクを避けるため、正本を1箇所に絞る方を優先し却下。
