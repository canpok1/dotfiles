{ config, pkgs, dotfilesDir, ... }:
{
  # 初回導入時の版。nixpkgs を更新しても据え置く（変えると既存の状態の扱いが変わる）
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    ansible
  ];

  # ホーム直下に張る symlink。左がホームからのパス、右が dotfiles 内の実体。
  # Nix の保管場所へコピーせず clone を直接指すので、実体の編集は switch なしで反映される。
  # スキルやルールを足したときは、ここにも1行足す（container/setup.sh とは別に持つ）
  home.file = {
    ".vimrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/vim/vimrc";

    ".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/claude/CLAUDE.md";
    ".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/claude/settings.json";
    ".claude/statusline.sh".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/claude/statusline.sh";
    ".claude/rules/brain-task.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/claude/rules/brain-task.md";
    ".claude/rules/claude-config.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/claude/rules/claude-config.md";
    ".claude/rules/coding.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/claude/rules/coding.md";
    ".claude/rules/investigation.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/claude/rules/investigation.md";
    ".claude/rules/work-log.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/claude/rules/work-log.md";
    ".claude/skills/create-adr".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/claude/skills/create-adr";
    ".claude/skills/daily-check".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/claude/skills/daily-check";
    ".claude/skills/discuss".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/claude/skills/discuss";
    ".claude/skills/retro".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/claude/skills/retro";
    ".claude/skills/skill-refine".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/claude/skills/skill-refine";
    ".claude/skills/task-refine".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/claude/skills/task-refine";
    ".claude/skills/wrap-up".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/claude/skills/wrap-up";
  };

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
