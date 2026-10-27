{ pkgs, ... }:
{
  # 初回導入時の版。nixpkgs を更新しても据え置く（変えると既存の状態の扱いが変わる）
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    ansible
  ];
}
