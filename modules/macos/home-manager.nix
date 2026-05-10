{ inputs, root, config, ... }: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "before-home-manager";
    sharedModules = [ inputs.nixvim.homeModules.nixvim ];
    extraSpecialArgs = {
      inherit root;
      userConfig = config.myConfig.user;
      themeConfig = config.myConfig.theme;
    };
  };
}
