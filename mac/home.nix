{ config, pkgs, dotfilesDir, ... }:
let
  # dotfiles の tools/<from> の中身を1件ずつ、ホームの <to> へ張る。
  # 中身は switch のたびに読み直すので、スキルやルールを足してもこのファイルは直さなくてよい
  # （flake は git 管理下のファイルしか読まないため、足したら git add してから switch する）
  linkEach = from: to:
    if builtins.pathExists ../tools/${from} then
      builtins.listToAttrs (map
        (name: {
          name = "${to}/${name}";
          value.source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/${from}/${name}";
        })
        (builtins.attrNames (builtins.readDir ../tools/${from})))
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
  // linkEach "claude/rules" ".claude/rules"     # tools/claude/rules/*  → ~/.claude/rules/*
  // linkEach "claude/skills" ".claude/skills"   # tools/claude/skills/* → ~/.claude/skills/*
  // linkEach "claude/agents" ".claude/agents";  # tools/claude/agents/* → ~/.claude/agents/*

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
