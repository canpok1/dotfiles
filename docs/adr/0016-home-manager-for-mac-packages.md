# 0016. mac のパッケージを home-manager で管理する

- ステータス: 採用
- 日付: 2026-10-27

## コンテキスト

mac に Ansible を入れたい。`setup.sh --init` は今、ツールごとに公式インストーラを curl で実行して導入している。Homebrew は 2026-06 に廃止済み（PR #3）。

home-manager は 0003 で「現時点では導入しない」とした。当時の見立ては、devcontainer と Claude Code on the web は起動ごとの使い捨てコンテナで毎回 Nix を入れると重いため、home-manager は mac ホスト向け、コンテナは `setup.sh` という二本立てになる、というもの。ユーザーは Ansible より先に home-manager の導入を望んだ。

## 決定

**mac のパッケージ導入を home-manager に任せる。設定ファイルの展開は全環境で `setup.sh` のまま残す。**

- 定義は `home-manager/flake.nix` と `home-manager/home.nix`。パッケージは `home.packages` に足す
- `setup.sh --init` が mac でのみ Nix を入れ（NixOS 公式の nix-installer）、`home-manager switch` を実行する
- ユーザー名・ホーム・CPU は実行環境から取る（`--impure`）。マシンごとに設定名を書き分けないため
- nixpkgs は darwin 向けの安定版ブランチ（`nixpkgs-26.05-darwin`）に固定し、`flake.lock` をコミットする

## 結果

良い影響: パッケージの追加が `home.nix` への1行で済み、版が `flake.lock` で揃う。設定ファイルの展開とプロファイルの絞り込みは `setup.sh` の1か所のままで、二重管理にならない。

悪い影響: mac とコンテナで導入手段が分かれる。コンテナでは `home.nix` のパッケージは入らない。mac 初回の `--init` で Nix の導入に sudo とダウンロード時間がかかる。

## 検討した代替案

- **設定ファイルの展開も home-manager へ移す**: mac は Nix に一本化できるが、コンテナ向けに `setup.sh` が残るため、プロファイルの絞り込みを2か所で持つことになる。必要になれば後から移せる。
- **Homebrew を戻す**: 2026-06 に廃止した方針と衝突する。
- **uv で Ansible だけ入れる**: 今の curl 方式に合うが、ツールごとに導入方法が増える構造は変わらない。
- **nix-darwin**: システム設定まで管理できるが、今の目的はユーザーのパッケージだけで過剰。
- **Determinate Nix Installer**: 実績はあるが、NixOS 公式の nix-installer が出たため公式を選んだ。
