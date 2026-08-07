---
name: work-log
description: 作業記録・日報を Obsidian vault のデイリーノートに追記する。実装や調査が一段落したとき、コミットやプルリクエストを作ったとき、方針を決めたとき、またはユーザーが「日報」「作業記録」「ログ」に言及したときに使う。
---

# 作業記録を Obsidian に残す

このスキルは [[obsidian-vault]] のデイリーノートへ作業記録を追記する。実行環境ごとに追記経路が異なるが、切り替えは `scripts/append.sh` が自動で行うため、呼び出し側は意識しなくてよい。

| | devcontainer | Claude Code on the web | ホスト直 |
|---|---|---|---|
| vault の実体 | 無い（clone しない） | 無い（clone しない） | ある |
| 追記経路 | GitHub Contents API（`gh api`） | GitHub Contents API（`gh api`） | `obsidian` CLI |

## 手順

### 1. プロジェクト名を決める

作業中のリポジトリ名を使う。

```bash
basename "$(git rev-parse --show-toplevel)"
```

git 管理下でない場合はディレクトリ名でよい。

### 2. 追記する

```bash
"$DOTFILES_DIR/claude/skills/work-log/scripts/append.sh" "<プロジェクト名>" "<本文>"
```

- 第1引数: プロジェクト名。`[[プロジェクト名]]` のリンクに使う
- 第2引数: 本文（見出しの下に入る）。複数行にする場合は `$'...\n...'` などで組み立てて渡す
- `DOTFILES_DIR` は `setup.sh` がシェル設定に export 済み
- 見出し（`## YYYY-MM-DD HH:MM JST [[プロジェクト名]]`）の生成と、リンク先のプロジェクトノート（`projects/<プロジェクト名>.md`）が無い場合の作成は `append.sh` が自動で行う
- 時刻は実行環境の TZ に関わらず常に JST 固定（`daily/YYYY-MM-DD.md` のファイル名の日付も同様）
- 追記後、結果を確認したい場合はホスト直なら `obsidian vault=obsidian-vault daily:read`、環境1・2 なら `gh api repos/canpok1/obsidian-vault/contents/daily/<日付>.md --jq '.content' | base64 -d`

### 3. 前提条件

- devcontainer / Claude Code on the web: `gh` コマンドが認証済みであること（`gh auth status` で確認）。vault の clone は不要 — `gh api` で GitHub を直接読み書きする
- ホスト直: Obsidian.app が起動していること（`obsidian` CLI は起動中の本体にソケット経由で指示を送るだけで、単体では動作しない）

## 書く内容

3〜6行程度。次の順で優先度が高い。

1. **ハマったことと原因** — 後から最も価値が出る。エラーの表面ではなく実際の原因を書く
2. **判断とその理由** — 何を選び、なぜ他を選ばなかったか
3. **何をしたか** — 手順ではなく結果で書く
4. **次にやること** — 中断したセッションを再開しやすくする

書かないもの: 実行したコマンドの逐語コピー、差分の羅列、自明な作業、その場限りの試行錯誤。

## 制約

- Vault は Private リポジトリだが、**認証情報・APIキー・トークン・秘密鍵は書かない**。値だけでなく「どこに置いてあるか」も避ける
- 顧客固有の機微な情報は、一般化した表現に置き換える
- **git 操作は不要**。devcontainer / web は `gh api` が直接コミットを作る。ホスト直は obsidian-git プラグインが10分以内に自動コミットする
- GitHub 側の一時的な競合（複数環境からの同時追記による 409/422）は `append.sh` が自動で数回リトライする。それでも失敗する場合はエラー出力を確認する
