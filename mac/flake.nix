# mac の設定ファイルの展開とパッケージの導入を home-manager で行う（docs/adr/0016）。
# mac/setup.sh から使う。
{
  description = "dotfiles: mac のユーザー環境";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      # ユーザー名・ホーム・CPU・clone の場所は実行した環境から取る（--impure が必要）。
      # マシンごとに設定を書き分けずに済ませるため。
      dotfilesDir = builtins.getEnv "DOTFILES_DIR";
    in
    {
      homeConfigurations.default =
        assert dotfilesDir != "" || throw "DOTFILES_DIR is not set (run mac/setup.sh)";
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${builtins.currentSystem};
          extraSpecialArgs = { inherit dotfilesDir; };
          modules = [
            ./home.nix
            {
              home.username = builtins.getEnv "USER";
              home.homeDirectory = builtins.getEnv "HOME";
            }
          ];
        };

      # mac/setup.sh が `nix run .#home-manager` で使う。
      # home-manager を事前に入れなくても、flake.lock と同じ版で起動できる
      packages = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-darwin" ] (system: {
        home-manager = home-manager.packages.${system}.default;
      });
    };
}
