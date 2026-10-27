{ pkgs, ... }:
{
  # 導入時の home-manager の版。上げると既存の状態の扱いが変わるため、版を上げても据え置く
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    ansible
  ];
}
