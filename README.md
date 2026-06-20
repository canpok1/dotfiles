dotfiles
========

各種設定ファイルを管理しています。

## （初回のみ）初期設定の方法

よく使うアプリのインストールとPC設定変更、設定ファイルの展開を行います。

1. githubからファイルを取得

    ```
    git clone http://github.com/canpok1/dotfiles.git ~/dotfiles
    ```

2. スクリプト実行（Mac、Linux）

    ```
    ./setup.sh --init
    ```

## 設定ファイルの展開方法

設定ファイルのみを再度展開します。
設定ファイルを削除してしまった時などに実行します。

1. スクリプトを実行（Mac、Linux）

    ```
    ./setup.sh
    ```

設定ファイルの展開時には、Claude 個人設定（`CLAUDE.md` / agents / skills）も `~/.claude` へ展開されます。

## Todoist 連携（workflow-scripts）の設定

`workflow-scripts`（auto-assign / auto-solve / solve-task など）は Todoist CLI（`td` = `@doist/todoist-cli`）を使います。
`td` は `./setup.sh --init` で導入されます。利用前に `~/.bash_profile_local` に以下を設定してください。
秘密情報・固有値は dotfiles にコミットせず `~/.bash_profile_local` に集約します。

```
export TODOIST_API_TOKEN=xxxx                  # Todoist の API トークン
export TODOIST_FILTER='#dev & /<リポジトリ名>'  # 対象タスクの絞り込みフィルタ
```

`workflow-scripts` は PATH に追加済みのため、対象としたい git リポジトリ内で直接実行できます
（git リポジトリ外で実行するとエラー終了します）。

## 設定ファイルの削除方法

1. セットアップスクリプトを実行（Mac、Linux）

    ```
    ./setup.sh --undeploy
    ```

    `~/.claude` へ展開した Claude 個人設定（CLAUDE.md / agents / skills の symlink）も併せて撤去します。

2. dotfilesフォルダを削除

