# タスク管理ルール

タスク（フォローアップ・バックログ・相談結果・スコープ外指摘の追跡など）の管理は Todoist で行う。各ルール・スキルはツール非依存の「タスク作成／更新／参照」として記述し、具体的な登録先・ツールは本ルールにのみ集約する。

## 登録先

- プロジェクト: `dev`
- セクション: **作業対象のリポジトリ名**（例: リポジトリ `foo` で作業しているなら セクション `foo`）

リポジトリ名は git から特定する（`basename "$(git rev-parse --show-toplevel)"`）。projectId / sectionId は名前から特定する（`mcp__todoist__find-projects` でプロジェクト `dev`、`mcp__todoist__find-sections` で対象リポジトリ名のセクションを引いて ID を得る）。対象セクションが見つからない場合は、作成してよいかをユーザーに確認する。

## タスクの作成・更新・参照

- **作成**: `mcp__todoist__add-tasks`（上記で引いた projectId / sectionId を指定する）
- **参照・重複確認**: `mcp__todoist__find-tasks`（`projectId` / `sectionId` で絞り込む）
- **更新**: `mcp__todoist__update-tasks` ／ **完了**: `mcp__todoist__complete-tasks`

## ラベル運用

タスクの状態管理には以下のラベルを使う。

- `<リポジトリ名>`: 対象リポジトリを示す（セクション名と同じリポジトリ名のラベル）
- `ready`: 着手してよい（対応可能）状態
- `assign-to-claude`: Claude が対応する対象
- `in-progress`: 対応中

### ラベル付与の方針

- **タスク作成時はラベルを一切付与しない** — LLM が新規タスクを作成するとき（`mcp__todoist__add-tasks`）は `labels` を指定せず（空のまま）作成すること。`ready` を含むいかなるラベルも自動付与してはならない。
- ラベルの付与・除去は、以下の定められたタイミング・担当でのみ行う。タスク作成者が先回りして状態ラベルを付けないこと。
    - `ready`: 人手で着手可否を判断して付与する。`solve-task` で作業を進められない状況になった場合は除去する（`~/.claude/skills/solve-task/SKILL.md` を参照）。
    - `assign-to-claude`: `assign-tasks` スキルが優先度評価のうえ付与する。
    - `in-progress`: `solve-task`（`solve-task.sh`）が着手時に付与し、終了時に除去する。

## タスク内容の書き方

- `content`: 何をするかを簡潔・具体的に書く（例: 「重複したバリデーション処理を共通ヘルパーへ抽出」）。
- `description`: 背景・根拠を Markdown で記載する。「どのメモ / PR のどの指摘か」を必ず明記し、後から再調査コストがかからないようにする。受け入れ条件があればチェックリストで含める。
- **重複登録を避ける** — 作成前に `find-tasks` で同種タスクの有無を確認し、あれば新規作成せず既存タスクへ追記する。

## ワークフロースクリプト（td CLI）

`~/dotfiles/workflow-scripts/` の自動化スクリプト（auto-assign / auto-solve / solve-task など。PATH 経由で実行可能）は、MCP ではなく Todoist CLI（`td` = `@doist/todoist-cli`）でタスクを参照・更新する。

- dotfiles の `setup.sh --init` で `td`（`@doist/todoist-cli`）が導入される。
- 認証は環境変数 `TODOIST_API_TOKEN` を使う。
- 対象タスクの絞り込みは環境変数 `TODOIST_FILTER`（例: `#dev & /<リポジトリ名>` = プロジェクト dev・対象リポジトリのセクション）を使う。`TODOIST_API_TOKEN` とともに `~/.bash_profile_local` に設定する。

## 注意

- Todoist タスクには `🤖 Generated with [Claude Code]...` フッターは不要（フッターは GitHub の PR・コメント向けの規約）。
- GitHub は PR・コードレビューにのみ使用し、タスク・バックログ管理には GitHub Issue を使わない。
