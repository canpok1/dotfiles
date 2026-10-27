# 0016. 環境ごとのディレクトリに分け、mac は home-manager で展開する

- ステータス: 採用
- 日付: 2026-10-27

## コンテキスト

mac に Ansible を入れたいという話から、mac の環境を home-manager で管理したいことになった。

これまでは全環境（mac・devcontainer・Claude Code on the web）を `setup.sh` 1本で扱っていた。設定ファイルは symlink とシェル設定への管理ブロック追記で配り、パッケージ導入は vox-actor の curl だけだった（Homebrew は 2026-06 に廃止済み）。

home-manager は 0003 で見送っている。理由は、コンテナは起動のたびに作り直されるので毎回 Nix を入れると重いこと。仕事用のマシンは mac で、mac にも私用/仕事の切り替えが要る。

## 決定

**リポジトリを `tools/`（ツールごとの設定の実体）・`mac/`・`container/`（環境ごとの展開手段）に分ける。mac は home-manager、コンテナは shell スクリプトで、どちらも `tools/` を指す symlink を張る。**

- どこに何を張るかとプロファイルの許可リストは、`mac/home.nix` と `container/setup.sh`・`container/profiles/work.conf` に**二重に持つ**。環境ごとに入れたいものが一致するとは限らないため
- mac の symlink は `mkOutOfStoreSymlink` で clone を直接指す。home-manager の既定（Nix の保管場所へコピー）だと、設定を試行錯誤するたびに switch が要るため
- ルートの `setup.sh` は残さない。呼び出し側（web 環境の設定スクリプトなど）を個別に直す
- mac では home-manager がシェル設定を丸ごと持つ。コンテナは既存ファイルを活かすため管理ブロック追記のまま
- mac の Nix は NixOS 公式の nix-installer で入れる。ユーザー名・ホーム・CPU・clone の場所は実行環境から取る（`--impure`）。マシンごとに設定を書き分けないため
- nixpkgs は darwin 向けの安定版ブランチに固定し、`flake.lock` をコミットする

## 結果

良い影響: 何を配るか（`tools/`）とどう配るか（環境ディレクトリ）が分かれ、環境を足すときに `tools/` を触らずに済む。mac はパッケージも宣言的に管理でき、版が `flake.lock` で揃う。編集の即時反映は今までどおり。

悪い影響: 設定を足したときに2か所を直す必要があり、片方だけ直してずれうる（README の構成の節で注意を促す）。mac では新しいファイルを `git add` しないと flake から見えない。ルートの `setup.sh` を消すので、既存の呼び出し側は直すまで壊れる。

## 検討した代替案

- **対応表とプロファイルを1か所に置き、Nix と sh の両方から読む**: ずれは防げるが、読み込む仕組みを作る必要がある。環境ごとに入れたいものが違ってよいので見送った。
- **mac はパッケージだけ home-manager にし、展開は全環境 `setup.sh`**: 変更は最小だが、mac を home-manager で管理したいという目的に届かない。
- **コンテナも home-manager にする**: 一本化できるが、起動のたびに Nix を入れて switch する重さが残る。
- **ルートに振り分け役の `setup.sh` を残す**: 呼び出し側を直さずに済むが、ユーザーは個別に直す方を選んだ。
- **Homebrew を戻す / uv で Ansible だけ入れる**: パッケージ導入しか解決しない。
- **nix-darwin**: システム設定まで管理できるが、今の目的はユーザー環境だけで過剰。
