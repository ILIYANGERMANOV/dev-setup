{ root, themeConfig, ... }:
let
  nvimStyle = {
    dark = "catppuccin_dark";
    light = "catppuccin_light";
    auto = "auto";
  }.${themeConfig};
in
{
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    myNixVim.style = nvimStyle;
    imports = [
      (import "${root}/programs/nvim")
    ];
  };
}
