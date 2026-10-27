{ config, lib, pkgs, profile, dotfilesDir, ... }:
let
  # Nix の保管場所へコピーせず clone を直接指す。設定の編集を switch なしで反映するため
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/tools/${path}";

  # flake は git 管理下のファイルしか見えないため、新しいスキル等は git add してから switch する
  entries = dir:
    lib.optionals (builtins.pathExists ../tools/${dir})
      (map (name: "${dir}/${name}") (builtins.attrNames (builtins.readDir ../tools/${dir})));

  claudeFiles = {
    private = [
      "claude/CLAUDE.md"
      "claude/settings.json"
      "claude/statusline.sh"
    ] ++ entries "claude/rules" ++ entries "claude/skills" ++ entries "claude/agents";

    # 許可リスト。コンテナの仕事プロファイルは container/profiles/work.conf に別に持つ
    work = [
      "claude/CLAUDE.md"
      "claude/settings.json"
      "claude/statusline.sh"
      "claude/rules/coding.md"
      "claude/rules/claude-config.md"
      "claude/rules/investigation.md"
      "claude/skills/retro"
      "claude/skills/wrap-up"
    ];
  }.${profile};
in
{
  # 初回導入時の版。nixpkgs を更新しても据え置く（変えると既存の状態の扱いが変わる）
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    ansible
  ];

  home.file = {
    ".vimrc".source = link "vim/vimrc";
  } // lib.listToAttrs (map (path: lib.nameValuePair ".${path}" { source = link path; }) claudeFiles);

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
