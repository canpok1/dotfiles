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

## vox-radio 個人設定の展開方法（opt-in）

Todoist 連携の Claude スキル / agents / CLAUDE.md を `~/.claude` へ展開し、
`workflow-scripts` が依存するツール（`td` = `@doist/todoist-cli`、`vox-actor`）を導入します。
vox-radio 専用のため通常の `setup.sh` には含まれず、明示的に指定したときのみ実行されます。

1. （未実施なら）まず通常の設定を展開する

    ```
    ./setup.sh
    ```

2. vox-radio 個人設定を展開する（Mac、Linux）

    ```
    ./setup.sh --vox-radio
    ```

3. `~/.bash_profile_local` に必要な環境変数を記載する

    `workflow-scripts`（auto-assign / auto-solve / solve-task など）は以下の環境変数を使います。
    秘密情報・固有値は dotfiles にコミットせず `~/.bash_profile_local` に集約します。

    ```
    export TODOIST_API_TOKEN=xxxx          # Todoist の API トークン
    export TODOIST_FILTER='#dev & /vox-radio'  # 対象タスクの絞り込みフィルタ
    ```

    `workflow-scripts` は PATH に追加済みのため、対象としたい git リポジトリ内で直接実行できます
    （git リポジトリ外で実行するとエラー終了します）。

## 設定ファイルの削除方法

1. セットアップスクリプトを実行（Mac、Linux）

    ```
    ./setup.sh --undeploy
    ```

    `~/.claude` へ展開した vox-radio 個人設定（CLAUDE.md / agents / skills の symlink）も併せて撤去します。

2. dotfilesフォルダを削除

