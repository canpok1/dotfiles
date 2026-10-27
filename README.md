dotfiles
========

各種設定ファイルを管理しています。

## 構成

```
tools/       ツールごとの設定の実体（claude/ shell/ vim/ workflow-scripts/）
mac/         mac 向け。home-manager の設定と setup.sh
container/   devcontainer / Claude Code on the web 向け。setup.sh とプロファイル定義
docs/adr/    判断の記録
```

どの環境でも `tools/` 配下を指す symlink を張り、clone 側を編集すれば展開し直さずに反映されます。
張り方は環境ごとに別に持ちます（mac は home-manager、コンテナは shell スクリプト）。
環境によって入れたいものが一致するとは限らないため、対応を二重に書くことを許容しています（`docs/adr/0016-environment-dirs-with-home-manager-on-mac.md`）。
**`tools/` に設定を足したら、mac は `mac/home.nix`、コンテナは `container/setup.sh` の両方を確認してください。**

各 setup.sh は自身の1つ上を dotfiles の実体として扱うため、clone 先は `~/dotfiles` でなくても構いません。

## mac

```
git clone https://github.com/canpok1/dotfiles.git ~/dotfiles && ~/dotfiles/mac/setup.sh
```

Nix が無ければ導入し（初回は sudo のパスワードを求められます）、`home-manager switch` で設定ファイルの展開とパッケージの導入を行います。何度実行しても構いません。

- 展開するものとパッケージ（Ansible など）は `mac/home.nix` に書きます。変えたら `mac/setup.sh` を再実行します
- **新しいファイル（スキルなど）は `git add` してから実行してください。** flake は git 管理下のファイルしか見えません
- シェル設定（`.zshrc` / `.zprofile` / `.bashrc` / `.bash_profile`）は home-manager が丸ごと持ち、`tools/shell/*.sh` を読み込みます。手を入れる場合は `~/.shell_local` に書いてください
- 既存のファイルと衝突した場合は `<対象>.hm-bak` へ退避してから置き換えます。旧 `setup.sh` が張った symlink は自動で外します
- nixpkgs の版は `mac/flake.lock` で固定しています。上げるときは `nix flake update --flake ./mac` を実行してコミットします
- 撤去は `home-manager uninstall` です

## コンテナ（devcontainer / Claude Code on the web）

```
git clone https://github.com/canpok1/dotfiles.git ~/dotfiles && ~/dotfiles/container/setup.sh --init
```

`--init` は設定ファイルの展開に加えて vox-actor を導入します。設定ファイルだけ展開し直すときは引数なしで実行します。
起動のたびに作り直される環境なので、Nix は使いません。

- `tools/vim/vimrc` や Claude 個人設定は symlink で展開します。既に同名の実体ファイル/ディレクトリ（symlink でないもの）があれば、上書きせず `<対象>.bak` に退避してから張ります
- シェル設定は symlink で置き換えず、`tools/shell/rc.sh` / `profile.sh` を読み込む管理ブロックを追記します。devcontainer などが先に置いたファイルの内容を活かすためです

    ```
    # >>> dotfiles managed block >>>
    export DOTFILES_DIR="/home/you/dotfiles"
    . "$DOTFILES_DIR/tools/shell/rc.sh"
    # <<< dotfiles managed block <<<
    ```

    再実行時はブロックの中身を最新へ書き替えます。手を入れる場合はブロックの外か `~/.shell_local` に書いてください。
- `DOTFILES_DIR` は dotfiles の配置場所を示す環境変数で、`tools/shell/profile.sh` の PATH 追加（`tools/workflow-scripts`）などで参照します
- `--undeploy` で撤去します。dotfiles を指す symlink と管理ブロックだけを外し、既存ファイル本体は残します

## プロファイル（私用 / 仕事）

環境によって使いたい設定が異なるため、展開する設定をプロファイル単位で選べます。
既定は `private` で、全ての設定が展開されます。`work`（仕事環境）では、brain リポジトリを前提とする設定を配りません。

| 対象 | private | work |
|---|---|---|
| vimrc / シェル設定 / `workflow-scripts` の PATH 追加 | ○ | ○ |
| `claude/CLAUDE.md` / `settings.json` / `statusline.sh` | ○ | ○ |
| `claude/rules/coding.md` / `claude-config.md` / `investigation.md` | ○ | ○ |
| `claude/rules/brain-task.md` / `work-log.md` | ○ | × |
| `claude/skills/retro` / `wrap-up` | ○ | ○ |
| `claude/skills/*`（`retro` `wrap-up` を除く） | ○ | × |
| `claude/agents/*` | ○ | × |

指定は以下の優先順で決まります（mac / コンテナ共通）。

```
mac/setup.sh --profile work              # ① 引数
DOTFILES_PROFILE=work mac/setup.sh       # ② 環境変数
echo work > ~/.dotfiles-profile          # ③ ファイル（一度書けば以後の再実行でも効く）
```

`private` と `work` 以外を指定するとエラー終了します（打ち間違いのまま私用設定が仕事環境へ入るのを防ぐため）。

仕事プロファイルで配るものは許可リストで、環境ごとに持ちます。**新しいスキルやルールは、書き足さない限り仕事環境には展開されません。**

- mac: `mac/home.nix` の `claudeFiles.work`
- コンテナ: `container/profiles/work.conf`（リポジトリルートからの相対パス。実在しないパスは警告します）

プロファイルを変えて再実行すると、除外された設定の symlink は撤去されます。

## Claude 個人設定

`tools/claude/` から `~/.claude` へ展開される主な設定は以下です。

なお、下記のうち `skills/` `agents/` と `rules/` の一部は `private` プロファイル限定です（[プロファイル](#プロファイル私用--仕事)を参照）。

- `CLAUDE.md` … 全プロジェクト共通の個人設定。言語など、環境を問わず適用する内容だけを置きます。
- `settings.json` … Claude Code の設定。ステータスライン（`~/.claude/statusline.sh`）を有効化するほか、`.env` や SSH 鍵など秘密情報を含みそうなファイルの閲覧・編集を `permissions.deny` で禁止します。
- `statusline.sh` … 起動ディレクトリ・モデル名・コンテキスト使用率・トークン数・コストを表示するステータスライン用スクリプト（`jq` が必要）。表示例: `/workspaces/dotfiles | Opus 5 | ctx 42% | 421.2k in / 1.5k out | $0.37`
- `skills/` … スキル群。相談から仕様・タスクを整理する `discuss`、着手可否が未判断のタスクを1件ずつ詳細化して仕分ける `task-refine`、重要判断を ADR として記録する `create-adr`、起きたことを掘り下げて「次はこうするとよい」の示唆を出す `retro`、毎日の定期作業をまとめて実行する `daily-check`、自作スキルをつまずきのパターンから週1回改善する `skill-refine`、作業終了前に予定した作業をやり切ったか確認して報告する `wrap-up` を含みます。`discuss` と `task-refine` はタスクの保存先に依存せず、登録先・状態の持ち方をタスク管理ルールに委ねます。`retro` と `wrap-up` は仕事プロファイルでも展開されます。
    - **ここに置くのは開発環境すべてで使いたいものだけです。** 特定のリポジトリでしか使わないスキルは、そのリポジトリの `.claude/skills/` に置きます（例: `web-clip` `meal-management` `work-log` `health-log` は canpok1/brain にあります）。
- `agents/` … エージェント定義。
- `rules/` … 共通ルール。`~/.claude/rules/` 配下は全プロジェクトに適用されます。`paths` を持つルールは該当ファイルを扱うときだけ、持たないルールはセッション開始時に読み込まれます。
    - `coding.md` … 作業の進め方（チェックリストを作って工程ごとに進める。自己レビューを含む）、コメントの書き方、コミット粒度。コードを扱うときに適用されます。
    - `claude-config.md` … Claude 設定（スキル・ルール・エージェント等）を変更するときのドキュメント反映確認と分量の測定。
    - `investigation.md` … 事実を調べて報告するときのルール。見つからないときに試す手（名前で引く・二次情報から辿る・親から辿る・相手に聞く）と、決め手になる事実の確かめ方。
    - `brain-task.md` … タスクの保存に brain リポジトリ（`canpok1/brain` の `tasks/`）を使う場合にのみ適用されるルール。保存先・ファイル命名・frontmatter・書き方・探し方に加え、パスの表記・`ready` にしてよい条件・`status`（`draft` / `ready` / `doing` / `done`）の遷移と done の定義を規定します（適用条件はファイル冒頭に記載）。`tasks/**/*.md` を扱うときに読み込まれます。
    - `work-log.md` … 作業記録を brain リポジトリのデイリーノートへ残す場合にのみ適用されるルール。`work-log` スキルを起動するタイミングを規定します（適用条件はファイル冒頭に記載）。スキル本体は canpok1/brain にあるため、brain 以外のリポジトリで記録するには `--add-dir` で brain を参照させます。

既に `~/.claude/settings.json` などの実体ファイルがある場合は、退避してから symlink を張ります（mac は `.hm-bak`、コンテナは `.bak`）。
