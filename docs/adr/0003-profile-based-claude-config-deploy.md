# 0003. Claude 設定をプロファイル単位で選択的に展開する

- ステータス: 採用
- 日付: 2026-08-08

## コンテキスト

`setup.sh` は `claude/skills/*/`・`claude/agents/*`・`claude/rules/*` をグロブで全件 `~/.claude/` へ symlink しており、環境ごとの取捨選択ができない。だが配布物には私用前提のものが含まれる。skills 全6件・`agents/task-assigner`・`rules/todoist.md`・`rules/obsidian-task.md` は Todoist / Obsidian vault を前提とし、仕事環境では使わない。

既存の `todoist.md` / `obsidian-task.md` が採る「冒頭に適用条件を書いて実行時に降りる」方式は適用の制御であり、配布は止まらない。description のトークン消費と誤起動が残る。

将来 home-manager で dotfiles 全体を再構成する構想があるが、devcontainer と Claude Code on the web は起動ごとに使い捨てのコンテナで dotfiles を clone し `setup.sh` を実行する。毎回 Nix を導入するのは起動コスト上現実的でなく、`setup.sh` は home-manager 導入後も残る見込み。

## 決定

プロファイル（`private` / `work`）単位の選択方式を採る。`claude/profiles/work.conf` に仕事環境で展開する対象を許可リストとして列挙し、`setup.sh` は指定プロファイルの conf に載るものだけを展開する。未指定時は全件展開（現行挙動）とし、私用は conf を持たない。

指定は `--profile` 引数 > `DOTFILES_PROFILE` 環境変数 > `~/.dotfiles-profile` の優先順で解決する。使い捨てコンテナは前2者、常設マシンはファイルで指定する。

併せて `CLAUDE.md` の work-log 言及を `rules/work-log.md` へ移し、両プロファイル共通の1枚に保つ。

## 結果

良い影響: 仕事環境へ私用前提の設定が入らない。許可リスト方式のため新規スキルを足しても仕事環境には自動で入らず、追加のたびの見直しが要らない。分類がテキスト1枚に集約され、home-manager 移行時は Nix のリストへ書き写せる。私用は conf を持たないため現行の展開結果が変わらない。

悪い影響: 仕事マシンで指定を忘れると全件展開されるフェイルオープンになる。`work.conf` と実ファイルの乖離を防ぐ仕組みも要る。

## 検討した代替案

- **機能バンドル（core / todoist / obsidian）単位**: 環境が増えても組合せで対応できるが、分類が私用/仕事の2値に収束したため中間概念が過剰。
- **プラグイン機構（skills-dir plugin）への移行**: skills・agents・hooks・MCP・bin を1単位で有効化できる標準機構だが、`rules/` が構成要素に無く二重管理となる。
- **配布は全件のまま適用条件の記述を徹底**: 実装コストは最小だが、トークン消費と誤起動が残る。
- **home-manager を先に導入し Nix 側だけで実装**: 使い捨てコンテナで Nix を使えず対象環境を覆えない。
