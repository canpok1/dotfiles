dotfiles
========

各種設定ファイルを管理しています。

## 構成

```
tools/       ツールごとの設定の実体（claude/ shell/ vim/）
mac/         mac 向け。home-manager の設定と setup.sh
container/   devcontainer / Claude Code on the web 向け。setup.sh
docs/adr/    判断の記録
```

どの環境でも `tools/` 配下を指す symlink を張るので、clone 側を編集すれば展開し直さなくても反映されます。
symlink を張る仕組みは環境ごとに別です（mac は home-manager、コンテナは shell スクリプト）。
環境によって入れたいものが一致するとは限らないため、どこに何を張るかは環境ごとに二重に書いています（`docs/adr/0016-environment-dirs-with-home-manager-on-mac.md`）。
**`tools/` に設定を足したら、mac は `mac/home.nix`、コンテナは `container/setup.sh` の両方を確認してください。**

各 setup.sh は自分の1つ上のディレクトリを dotfiles の置き場所として扱うため、clone 先は `~/dotfiles` でなくても構いません。

## 初期設定

```
# mac（Nix は導入済みの前提）
git clone https://github.com/canpok1/dotfiles.git ~/dotfiles && ~/dotfiles/mac/setup.sh

# コンテナ
git clone https://github.com/canpok1/dotfiles.git ~/dotfiles && ~/dotfiles/container/setup.sh
```

詳しくは各ディレクトリの README を見てください。

- [mac/README.md](mac/README.md) … mac での展開・パッケージの追加・撤去
- [container/README.md](container/README.md) … コンテナでの展開・シェル設定の管理ブロック・撤去
- [tools/claude/README.md](tools/claude/README.md) … `~/.claude` へ展開する Claude 個人設定の一覧
