# コンテナ（devcontainer / Claude Code on the web）

```
git clone https://github.com/canpok1/dotfiles.git ~/dotfiles && ~/dotfiles/container/setup.sh
```

設定ファイルを消してしまったときなどは `container/setup.sh` を再実行すれば展開し直せます。
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
- `container/undeploy.sh` で撤去します。dotfiles を指す symlink と管理ブロックだけを外し、既存ファイル本体は残します
