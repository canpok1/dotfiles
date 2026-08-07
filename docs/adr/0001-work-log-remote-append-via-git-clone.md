# 0001. work-log-remote-append-via-git-clone

- ステータス: 採用
- 日付: 2026-08-07

## コンテキスト

work-log スキルは devcontainer / Claude Code on the web から obsidian-vault のデイリーノートへ追記する必要がある。当初案（obsidian-vault の `tasks/dotfiles/2026-08-08-work-log.md`）は、この2環境で GitHub Contents API（`gh api`）を直接叩く方式を採用し、vault の clone は作らない前提だった。

実装後に Claude Code on the web（Claude Code Remote）セッションで検証したところ、`gh` コマンドが存在せず、`api.github.com` への直接アクセスも組織ポリシーで拒否される（HTTP 403 "GitHub access is not enabled for this session"）ことが判明した。`gh` を追加インストールしても同じ403で拒否される。一方このセッションは git push は可能で、対象リポジトリが session に clone 済みだった。

## 決定

devcontainer / web 向けの追記経路を、GitHub Contents API から「obsidian-vault のローカル clone への `git commit` + `push`」へ変更する。clone が見つからない場合は追記をスキップし、エラーにはしない。記録するかどうかは、vault を clone しているかどうかでユーザーが制御する。push 競合時は fetch + fast-forward-only merge を試み、失敗時は自分の commit だけを `reset --hard` で取り消して最大3回再試行する。作業ツリーが汚れている場合は中断する。

## 結果

良い影響: 依存が `git` だけになり、`gh` の有無やAPIアクセス可否に左右されなくなる。base64エンコードやSHA楽観ロックの実装が不要になり単純化した。

悪い影響: 記録の可否が「clone しているか」という暗黙的な状態に依存し、ユーザーが意図せず記録漏れに気づきにくい（SKILL.md に明記して緩和）。長時間セッションで clone が古くなった場合、fast-forward-only merge が失敗して追記が中断されうる。

## 検討した代替案

- **gh api 継続**: 当初案。Claude Code Remote 系セッションで `gh` 非搭載・API直叩き禁止のため機能しないと判明し却下。
- **gh api を主、git push をフォールバック**: 環境ごとに2経路を保守するコストが高く、git push 単独で全環境をカバーできるため不要と判断。
- **clone が無ければ自動 clone**: 当初設計が避けた「陳腐化・手動fetch管理」の問題が戻るため却下。
