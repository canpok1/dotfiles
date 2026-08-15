# Architecture Decision Records (ADR)

重要度の高い判断を記録する。フォーマットは MADR 軽量版（日本語本文）。

| 番号 | タイトル | ステータス | 日付 |
|------|----------|------------|------|
| [0001](0001-work-log-remote-append-via-git-clone.md) | work-log の devcontainer/web 向け追記経路を gh api から git push へ変更 | 採用 | 2026-08-07 |
| [0002](0002-obsidian-task-rule-in-dotfiles.md) | Obsidian タスクファイルの書き方ルールを obsidian-vault から dotfiles へ移動 | 採用 | 2026-08-08 |
| [0003](0003-profile-based-claude-config-deploy.md) | 設定をプロファイル単位で選択的に展開する | 採用 | 2026-08-08 |
| [0004](0004-task-status-in-frontmatter-not-directory.md) | タスクのステータスは frontmatter で持ちディレクトリでは表現しない | 採用 | 2026-08-09 |
| [0005](0005-task-status-draft-ready-split.md) | タスクのステータス todo を draft と ready に分割する | 採用 | 2026-08-09 |
| [0006](0006-dropped-status-for-discarded-tasks.md) | 破棄したタスクを表す status として dropped を追加する | 採用 | 2026-08-09 |
| [0007](0007-ready-at-creation-via-consultation.md) | 相談を経て作成するタスクは着手可能な状態で起票する | 採用 | 2026-08-09 |
| [0008](0008-backend-agnostic-refine-task-skill.md) | タスクのリファインメントを保存先非依存のスキル1つに統合する | 採用 | 2026-08-09 |
| 0009 | （欠番）スマホからの web クリップ受け皿に Google ドライブを使う | 移設 | 2026-08-14 |
| 0010 | （欠番）コネクタが必要な処理の定期実行を見送り手動起動で運用する | 移設 | 2026-08-15 |

このリポジトリには **開発環境すべてで使う設定に関する判断** を置く。特定のリポジトリに固有の判断はそのリポジトリ側に置く。

0009 と 0010 は web クリップ取り込み（obsidian-vault 固有の機能）についての判断だったため、`web-clip` スキルとともに canpok1/obsidian-vault の `projects/obsidian-vault/adr/` へ 0001 / 0002 として移設した。**欠番として残し、この番号は再利用しない**（既存のデイリーノートやコミットメッセージが旧番号で参照しているため）。
