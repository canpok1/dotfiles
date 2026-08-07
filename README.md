dotfiles
========

各種設定ファイルを管理しています。

## （初回のみ）初期設定の方法

よく使うアプリのインストールと設定ファイルの展開を、以下の1コマンドで行います（Mac / Linux、要 git）。

```
git clone https://github.com/canpok1/dotfiles.git ~/dotfiles && ~/dotfiles/setup.sh --init
```

`setup.sh` は自身が置かれているディレクトリを dotfiles の実体として扱うため、clone 先は `~/dotfiles` でなくても構いません
（例: `/workspaces/dotfiles` に clone してそこの `setup.sh` を実行すれば、そのクローンを指すリンクが張られます）。

## 設定ファイルの展開方法

設定ファイルのみを再度展開します。
設定ファイルを削除してしまった時などに実行します。

1. スクリプトを実行（Mac、Linux）

    ```
    ~/dotfiles/setup.sh
    ```

    `_vimrc` や Claude 個人設定は symlink で展開します。既に同名の実体ファイル/ディレクトリ
    （symlink でないもの）が存在する場合は、上書きせず `<対象>.bak` に退避してから symlink を張ります
    （2回目以降の symlink 張り替えでは退避しません）。

    シェル設定（`.bashrc` / `.zshrc` / `.zprofile` / `.bash_profile`）は symlink で置き換えず、
    dotfiles の共通設定（`shell/rc.sh` / `shell/profile.sh`）を読み込む管理ブロックを追記します。
    これにより devcontainer などで既にこれらのファイルが配置されている場合でも、
    既存の内容を活かしたまま dotfiles の設定を併用できます（`.bak` への退避は行いません）。
    管理ブロックは `# >>> dotfiles managed block >>>` ～ `# <<< dotfiles managed block <<<` で囲まれ、
    以下の内容が書き込まれます。

    ```
    # >>> dotfiles managed block >>>
    export DOTFILES_DIR="/home/you/dotfiles"
    . "$DOTFILES_DIR/shell/rc.sh"
    # <<< dotfiles managed block <<<
    ```

    再実行時は重複追記せず、ブロックの中身を最新内容へ書き替えます（dotfiles を別の場所へ移した場合もパスが追従します）。
    ブロック内は毎回上書きされるため、手を入れる場合はブロックの外か `~/.shell_local` に書いてください。
    旧バージョンで張られた dotfiles 向け symlink は、実体ファイルへ自動で作り直します。

    `DOTFILES_DIR` は dotfiles の配置場所を示す環境変数で、`shell/profile.sh` の PATH 追加（`workflow-scripts`）などで参照します。

設定ファイルの展開時には、Claude 個人設定（`CLAUDE.md` / `settings.json` / `statusline.sh` / agents / skills / rules）も `~/.claude` へ展開されます。

## Claude 個人設定

`~/.claude` へ展開される主な設定は以下です。

- `CLAUDE.md` … 全プロジェクト共通の個人設定。
- `settings.json` … Claude Code の設定。ステータスライン（`~/.claude/statusline.sh`）を有効化します。
- `statusline.sh` … 起動ディレクトリ・モデル名・コンテキスト使用率・トークン数・コストを表示するステータスライン用スクリプト（`jq` が必要）。表示例: `/workspaces/dotfiles | Opus 5 | ctx 42% | 421.2k in / 1.5k out | $0.37`
- `skills/` … スキル群。`todoist-` で始まるものは Todoist でのタスク管理を前提とします（`todoist-solve-task` / `todoist-assign-tasks` / `todoist-triage-task`）。ほかに、相談から仕様・タスクを整理する `discuss`、重要判断を ADR として記録する `create-adr`、作業記録を Obsidian vault のデイリーノートに追記する `work-log` を含みます。
- `agents/` … エージェント定義。
- `rules/` … 共通ルール。`~/.claude/rules/` 配下は全プロジェクトに適用されます。`paths` を持つルールは該当ファイルを扱うときだけ、持たないルールはセッション開始時に読み込まれます。
    - `coding.md` … 実装後の品質確認・自己レビュー、コメントの書き方、コミット粒度。コードを扱うときに適用されます。
    - `claude-config.md` … Claude 設定（スキル・ルール・エージェント等）を変更するときのドキュメント反映確認。
    - `todoist.md` … タスク管理に Todoist を使う場合にのみ適用されるルール。Todoist を使わないプロジェクトには適用されません（適用条件はファイル冒頭に記載）。

既に `~/.claude/settings.json` などの実体ファイルがある場合は、`<対象>.bak` へ退避してから symlink を張ります。

## Todoist 連携（workflow-scripts）の設定

`workflow-scripts` のうち `todoist-` で始まるスクリプト（`todoist-auto-assign.sh` / `todoist-auto-solve.sh` / `todoist-solve-task.sh`）は
Todoist CLI（`td` = `@doist/todoist-cli`）を使います（共通処理は `todoist-lib.sh`）。
`td` は `~/dotfiles/setup.sh --init` で導入されます。

### 認証（どちらか一方）

- **コマンドでログイン**: `td auth login`（ブラウザで OAuth 認証。トークンは OS の資格情報ストアに保存される）
- **環境変数で指定**: `~/.shell_local` に `TODOIST_API_TOKEN` を設定する（環境変数が優先される）

    ```
    export TODOIST_API_TOKEN=xxxx   # Todoist Settings > Integrations > Developer で取得
    ```

### タスクの絞り込み対象

`todoist-auto-assign` / `todoist-auto-solve` が巡回する対象タスクは、実行したカレントの git リポジトリから自動的に決まります
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

    `~/.claude` へ展開した Claude 個人設定（CLAUDE.md / agents / skills / rules の symlink）も併せて撤去します。
    シェル設定からは追記した管理ブロックのみを取り除き、既存ファイル本体（devcontainer などが配置した内容）は残します。

2. dotfilesフォルダを削除

