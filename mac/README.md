# mac

```
git clone https://github.com/canpok1/dotfiles.git ~/dotfiles && ~/dotfiles/mac/setup.sh
```

Nix（flakes 有効）は先に入れておいてください。home-manager は不要です。`mac/setup.sh` が home-manager を flake 経由で起動し、設定ファイルの展開とパッケージの導入を行います。何度実行しても構いません。

- 展開するもの（どこにどのファイルを張るか）とパッケージ（Ansible など）は `mac/home.nix` に書きます。変えたら `mac/setup.sh` を再実行します
- `tools/claude/` のスキル・ルール・エージェントは自動で全部張ります。**新しく足したときは `git add` してから `mac/setup.sh` を再実行してください。** flake は git で管理しているファイルしか読み込みません
- シェル設定（`.zshrc` / `.zprofile` / `.bashrc` / `.bash_profile`）は home-manager がファイルごと生成し、その中で `tools/shell/*.sh` を読み込みます。手を入れる場合は `~/.shell_local` に書いてください
- 既存のファイルと衝突した場合は `<対象>.hm-bak` へ退避してから置き換えます
- nixpkgs の版は `mac/flake.lock` で固定しています。上げるときは `nix flake update --flake ./mac` を実行してコミットします
- 撤去するときは `home-manager uninstall` を実行します
