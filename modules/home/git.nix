{ pkgs, userConfig, ... }: {
  home.packages = with pkgs; [
    pre-commit
    gh
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user.name = userConfig.fullName;
      user.email = userConfig.email;
      init.defaultBranch = "main";
    };
  };
}
