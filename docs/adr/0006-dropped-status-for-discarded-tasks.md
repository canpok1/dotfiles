# 0006. 破棄したタスクを表す status として dropped を追加する

- ステータス: 採用
- 日付: 2026-08-09

## コンテキスト

`docs/adr/0005-task-status-draft-ready-split.md` で `status` を `draft` / `ready` / `doing` / `done` の4値に定めた。その後、`draft` を `ready` へ昇格させるかを判断するスキル（Obsidian 版の triage）を検討したところ、「やらないと決めた」タスクの置き場が無いことが分かった。

Todoist 側の同等スキル `todoist-triage-task` は、破棄を「削除せず完了扱い」で表現している。誤判断時の復元とトレースを残すためである。Obsidian 側の `status` には終端が `done` しか無い。

## 決定

**破棄したタスクを表す5つめの値 `dropped` を追加する。** `status` は `draft` / `ready` / `doing` / `done` / `dropped` となる。

- `dropped`: 実施しないと決めた。破棄理由を本文に書いてから `dropped` にする
- ファイルは削除せず残す。他タスクからの参照を壊さないため（`docs/adr/0004-task-status-in-frontmatter-not-directory.md`）
- `done` は「やり切った」だけを指す。「done の定義」の2条件は変更しない

`obsidian-vault/tasks/view.base` の「未完了」ビューは `status != "done"` フィルタのため、`dropped` を除外するよう修正する。修正しないと破棄済みタスクが未完了として残り続ける。

## 結果

良い影響: 終端の2状態が区別でき、一覧で「やり切った」と「やめた」を読み分けられる。破棄が `status` の1行で表せる。`todoist-triage-task` の「削除せず記録を残す」方針とも揃う。

悪い影響: 値が5つに増え、`status` で絞り込む箇所（Bases のビュー、`rg` の抽出）で `dropped` の扱いを都度考える必要が生じる。とくに「未完了」が `!= done` の一箇所判定では済まなくなる。

## 検討した代替案

- **`done` を流用する**: `obsidian-task.md` の「やらないことにした受け入れ条件は打ち消し線を引き `[x]` 判定から除外する」仕組みを使えば形式的には成立し、`view.base` の変更も要らない。しかし `done` が「やり切った」と「やめた」を兼ね、ADR 0005 で解消した「`todo` が2つの意味を兼ねる」問題を作り直すため却下
- **ファイルごと削除する**: 一覧はきれいになるが、他タスクからのプレーンパス参照が壊れる。ADR 0004 とも衝突するため却下
- **`draft` のまま据え置く**: 変更は要らないが `draft` の一覧が判断済みで埋まり、`rg -l '^status: draft'` が triage 対象の抽出として機能しなくなるため却下
