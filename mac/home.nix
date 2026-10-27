{ config, pkgs, dotfilesDir, ... }:
let
  # dotfiles 内のディレクトリ toDotfiles の中身を1件ずつ、ホームの inHome へ張る。
  # 中身は switch のたびに読み直すので、スキルやルールを足してもこのファイルは直さなくてよい
  # （flake は git 管理下のファイルしか読まないため、足したら git add してから switch する）
  linkEach = { inHome, toDotfiles }:
    if builtins.pathExists ../${toDotfiles} then
      builtins.listToAttrs (map
        (name: {
          name = "${inHome}/${name}";
          value.source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${toDotfiles}/${name}";
        })
        (builtins.attrNames (builtins.readDir ../${toDotfiles})))
    else { };
in
{
  # 初回導入時の版。nixpkgs を更新しても据え置く（変えると既存の状態の扱いが変わる）
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    ansible
  ];

  # ホームに張る symlink。左がホームからのパス、右が dotfiles 内の実体。
  # Nix の保管場所へコピーせず clone を直接指すので、実体の編集は switch なしで反映される
  home.file = {
    ".vimrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/vim/vimrc";
    ".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/claude/CLAUDE.md";
    ".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/claude/settings.json";
    ".claude/statusline.sh".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/claude/statusline.sh";
  }
  // linkEach { inHome = ".claude/rules";  toDotfiles = "tools/claude/rules"; }
  // linkEach { inHome = ".claude/skills"; toDotfiles = "tools/claude/skills"; }
  // linkEach { inHome = ".claude/agents"; toDotfiles = "tools/claude/agents"; };

  home.sessionVariables.DOTFILES_DIR = dotfilesDir;

  programs.zsh = {
    enable = true;
    profileExtra = ''. "$DOTFILES_DIR/tools/shell/profile.sh"'';
    initContent = ''. "$DOTFILES_DIR/tools/shell/rc.sh"'';
  };

  programs.bash = {
    enable = true;
    profileExtra = ''. "$DOTFILES_DIR/tools/shell/profile.sh"'';
    initExtra = ''. "$DOTFILES_DIR/tools/shell/rc.sh"'';
  };
}
