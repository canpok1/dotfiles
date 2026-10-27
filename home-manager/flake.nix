# mac ホストのパッケージを home-manager で管理する（docs/adr/0016）。
# 設定ファイルの展開は setup.sh の担当で、ここでは扱わない。
{
  description = "dotfiles: mac のパッケージ管理";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
    in
    {
      # ユーザー名・ホーム・CPU は実行した環境から取る（--impure が必要）。
      # マシンごとに名前を書き分けずに済ませるため。
      homeConfigurations.default = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${builtins.currentSystem};
        modules = [
          ./home.nix
          {
            home.username = builtins.getEnv "USER";
            home.homeDirectory = builtins.getEnv "HOME";
          }
        ];
      };

      # 初回の switch 用。home-manager コマンドを flake.lock と同じ版で起動する
      packages = nixpkgs.lib.genAttrs darwinSystems (system: {
        default = home-manager.packages.${system}.default;
      });
    };
}
