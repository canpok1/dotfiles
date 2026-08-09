# 0004. task-status-in-frontmatter-not-directory

- ステータス: 採用
- 日付: 2026-08-09

## コンテキスト

Obsidian vault のタスクは `tasks/<repo名>/<file>.md` に置き、ステータスは frontmatter の `status`（`todo` / `doing` / `done`）で持つ。この構成では、どのタスクが未着手かを知るのにファイルを開く必要があり、一覧性が無い。

そこで保存先を `tasks/<repo名>/<status>/<file>.md` に変え、ディレクトリ構成でステータスを表現する案が出た。GitHub のファイルブラウザで vault を眺めたときに一目で分かることが動機だった。

判断の前提として、vault の実態を確認した。

- タスクは8件（`tasks/dotfiles/` 6件、`tasks/obsidian-vault/` 2件）
- タスク同士の参照は `tasks/<repo名>/<file>.md` 形式のプレーンパス（コードスパン内）であり、`[[wikilink]]` ではない。この表記自体もタスク `20260809102806-task-done-definition` の決定事項7で規定されたもの
- 参照先には `status: done` のタスクが含まれる（`tasks/dotfiles/20260808004235-work-log.md` は4箇所から参照されている）
- `claude/rules/obsidian-task.md` は既に「ステータスが変わってもファイルを移動しない。frontmatter を書き換える」と定めており、理由として「コンテナから GitHub API 等で更新する際に削除+作成にならないため」を挙げている
- vault の `.obsidian/core-plugins.json` で Bases がコアプラグインとして有効になっている

## 決定

**タスクのステータスの正本は frontmatter の `status` とし、ディレクトリ構成では表現しない。** 保存先は `tasks/<repo名>/<file>.md` のまま維持する。

一覧性の課題は、保存先ではなく閲覧手段で解決する。用途ごとに手段を分ける。

- 人間は Obsidian の Bases ビュー（`tasks/tasks.base`）で見る
- Claude Code は vault のルートで `rg` を使う（`rg -l '^status: todo' tasks/` など）

当初の動機だった「GitHub のファイルブラウザで一目で分かること」は要件から外し、人間の閲覧は Obsidian に寄せる。

## 結果

良い影響: タスク間のプレーンパス参照が壊れない。ステータス更新が frontmatter の1行書き換えで済み、GitHub API 経由でも削除+作成にならない。ステータスが frontmatter だけに存在するため、ディレクトリとの二重管理によるズレが起きない。ファイル単体で自己記述的である性質（`project` をディレクトリ名と重複させてでも残している方針）と整合する。ステータス以外の軸（プロジェクト・作成日）でも絞り込めるため、ディレクトリ1軸より表現力が高い。

悪い影響: GitHub のファイルブラウザ上ではステータスが分からないままになる。Obsidian を開けない環境の人間は `rg` を使うことになる。Bases ビューという Obsidian 固有機能への依存が1つ増える。

## 検討した代替案

- **`tasks/<repo名>/<status>/<file>.md` に分ける**: GitHub のファイルブラウザで一目で分かるようになるが、(1) プレーンパスのタスク間参照がステータス変更のたびに壊れる、(2) `obsidian-task.md` の「移動しない」という既存の決定と衝突する、(3) frontmatter とディレクトリでステータスが二重管理になる、の3点により却下。二重管理は frontmatter から `status` を落とせば解消するが、ファイル単体の自己記述性を失うため採らない。
- **`done` のときだけ `tasks/<repo名>/done/` へ移す**: 移動が1タスクにつき1回で済み傷は浅いが、`done` のタスクが他タスクから参照されている実例があるため参照切れは避けられず、部分的な解決にしかならないため却下。
- **ファイル名の先頭または末尾にステータスを含める**: ディレクトリ案と同じくリネームが発生し、参照が壊れるため却下。加えて `YYYYMMDDHHMMSS-<slug>.md` という作成順で並べるための命名規則を崩す。
- **`tasks/<repo名>/README.md` にインデックスを置く**: GitHub 上でも読めるが、タスクの追加・状態変更のたびに手で更新する必要があり、実体とのズレが必ず生じるため却下。
