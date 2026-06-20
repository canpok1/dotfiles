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
`td` は `./setup.sh --init` で導入されます。

### 認証（どちらか一方）

- **コマンドでログイン**: `td auth login`（ブラウザで OAuth 認証。トークンは OS の資格情報ストアに保存される）
- **環境変数で指定**: `~/.bash_profile_local` に `TODOIST_API_TOKEN` を設定する（環境変数が優先される）

    ```
    export TODOIST_API_TOKEN=xxxx   # Todoist Settings > Integrations > Developer で取得
    ```

### タスクの絞り込みフィルタ（auto-assign / auto-solve 用）

`auto-assign` / `auto-solve` は、どのタスクを対象に巡回するかを環境変数 `TODOIST_FILTER` で決めます。
これは Todoist のフィルタクエリで、スクリプト内で状態ラベル条件（`@ready` / `@assign-to-claude` / `@in-progress` など）と
AND 結合して対象タスクを絞り込みます。`~/.bash_profile_local` に設定してください。

```
export TODOIST_FILTER='#dev & /<リポジトリ名>'  # 例: プロジェクト dev・対象リポジトリ名のセクション
```

秘密情報・固有値は dotfiles にコミットせず `~/.bash_profile_local` に集約します。

`workflow-scripts` は PATH に追加済みのため、対象としたい git リポジトリ内で直接実行できます
（git リポジトリ外で実行するとエラー終了します）。

## 設定ファイルの削除方法

1. セットアップスクリプトを実行（Mac、Linux）

    ```
    ./setup.sh --undeploy
    ```

    `~/.claude` へ展開した Claude 個人設定（CLAUDE.md / agents / skills の symlink）も併せて撤去します。

2. dotfilesフォルダを削除

