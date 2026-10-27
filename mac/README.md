# mac

```
git clone https://github.com/canpok1/dotfiles.git ~/dotfiles && ~/dotfiles/mac/setup.sh
```

Nix（flakes 有効）と home-manager は先に入れておいてください。`mac/setup.sh` は `home-manager switch` を実行し、設定ファイルの展開とパッケージの導入を行います。何度実行しても構いません。

- 展開するものとパッケージ（Ansible など）は `mac/home.nix` に書きます。変えたら `mac/setup.sh` を再実行します
- **新しいファイル（スキルなど）は `git add` してから実行してください。** flake は git で管理しているファイルしか読み込みません
- シェル設定（`.zshrc` / `.zprofile` / `.bashrc` / `.bash_profile`）は home-manager がファイルごと生成し、その中で `tools/shell/*.sh` を読み込みます。手を入れる場合は `~/.shell_local` に書いてください
- 既存のファイルと衝突した場合は `<対象>.hm-bak` へ退避してから置き換えます。旧 `setup.sh` が張った symlink は自動で外します
- nixpkgs の版は `mac/flake.lock` で固定しています。上げるときは `nix flake update --flake ./mac` を実行してコミットします
- 撤去するときは `home-manager uninstall` を実行します
