dotfiles
========

各種設定ファイルを管理しています。

## （初回のみ）初期設定の方法

よく使うアプリのインストールと設定ファイルの展開を行います。

1. githubからファイルを取得

    ```
    git clone http://github.com/canpok1/dotfiles.git ~/dotfiles
    ```

2. スクリプト実行（Mac、Linux）

    ```
    ~/dotfiles/setup.sh --init
    ```

## 設定ファイルの展開方法

設定ファイルのみを再度展開します。
設定ファイルを削除してしまった時などに実行します。

1. スクリプトを実行（Mac、Linux）

    ```
    ~/dotfiles/setup.sh
    ```

    既に同名の実体ファイル/ディレクトリ（symlink でないもの）が存在する場合は、
    上書きせず `<対象>.bak` に退避してから symlink を張ります（2回目以降の symlink 張り替えでは退避しません）。

設定ファイルの展開時には、Claude 個人設定（`CLAUDE.md` / agents / skills）も `~/.claude` へ展開されます。

## Todoist 連携（workflow-scripts）の設定

`workflow-scripts`（auto-assign / auto-solve / solve-task など）は Todoist CLI（`td` = `@doist/todoist-cli`）を使います。
`td` は `~/dotfiles/setup.sh --init` で導入されます。

### 認証（どちらか一方）

- **コマンドでログイン**: `td auth login`（ブラウザで OAuth 認証。トークンは OS の資格情報ストアに保存される）
- **環境変数で指定**: `~/.shell_local` に `TODOIST_API_TOKEN` を設定する（環境変数が優先される）

    ```
    export TODOIST_API_TOKEN=xxxx   # Todoist Settings > Integrations > Developer で取得
    ```

### タスクの絞り込み対象

`auto-assign` / `auto-solve` が巡回する対象タスクは、実行したカレントの git リポジトリから自動的に決まります
（プロジェクト `dev` / セクション = リポジトリ名）。スクリプト内で `#dev & /<リポジトリ名>` というフィルタを組み立て、
状態ラベル条件（`@ready` / `@assign-to-claude` / `@in-progress` など）と AND 結合して絞り込みます。
そのため対象の指定に環境変数は不要です。

`workflow-scripts` は PATH に追加済みのため、対象としたい git リポジトリ内で直接実行できます
（git リポジトリ外で実行するとエラー終了します）。

## 設定ファイルの削除方法

1. セットアップスクリプトを実行（Mac、Linux）

    ```
    ~/dotfiles/setup.sh --undeploy
    ```

    `~/.claude` へ展開した Claude 個人設定（CLAUDE.md / agents / skills の symlink）も併せて撤去します。

2. dotfilesフォルダを削除

