{ lib, config, ... }:

let
  cfg = config.myNixVim;
in
{
  options.myNixVim.style = lib.mkOption {
    type = lib.types.enum [ "catppuccin_light" "catppuccin_dark" "tokyonight" "auto" ];
    default = "catppuccin_dark";
    description = "Select the color theme for NeoVim.";
  };

  config = lib.mkMerge [

    # --- BASE UI & STYLING CONFIGURATION ---
    {
      opts = {
        termguicolors = true;
      };

      plugins = {
        # Core Icons
        web-devicons.enable = true;

        # Next-Gen UI (Command line, search, and notifications)
        notify = {
          enable = true;
          settings = {
            backgroundColour = "#000000";
            timeout = 1500;
          };
        };
        noice = {
          enable = true;
          settings.presets = {
            bottom_search = true;
            command_palette = true;
            long_message_to_split = true;
            lsp_doc_border = true;
          };
        };

        # Statusline and Tabline
        lualine = {
          enable = true;
          settings.options = {
            component_separators = { left = "│"; right = "│"; };
            section_separators = { left = ""; right = ""; };
            theme = "auto";
          };
        };
        bufferline.enable = true;

        # Indentation Guides
        indent-blankline = {
          enable = true;
          settings.scope = {
            enabled = true;
            show_start = true;
          };
        };

        # Keybinding hints popup
        which-key.enable = true;

        # Smooth scrolling
        neoscroll.enable = true;

        # Welcome Dashboard
        alpha = {
          enable = true;
          theme = "dashboard";
        };

        # Nvim-Tree Styling (merges with file-tree.nix settings)
        nvim-tree = {
          enable = true;
          settings = {
            view.width = 30;
            renderer = {
              indent_markers.enable = true;
              icons.glyphs.folder = {
                arrow_closed = "";
                arrow_open = "";
              };
            };
          };
        };

        # Telescope Styling (merges with search.nix settings.defaults)
        telescope = {
          enable = true;
          settings.defaults = {
            prompt_prefix = "   ";
            selection_caret = "  ";
            # Enforce rounded borders for telescope
            borderchars = [ "─" "│" "─" "│" "╭" "╮" "╯" "╰" ];
          };
        };

        # Enforce rounded borders for completion windows (merges with auto-complete.nix)
        cmp.settings.window = {
          completion.border = "rounded";
          documentation.border = "rounded";
        };
      };

      keymaps = [
        {
          mode = "n";
          key = "<leader>nd";
          action = "<cmd>NoiceDismiss<CR>";
          options.desc = "Dismiss notifications";
        }
      ];

      # Enforce rounded borders for LSP hovers and diagnostics globally
      extraConfigLua = ''
        local _border = "rounded"
        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = _border })
        vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = _border })
        vim.diagnostic.config{ float={border=_border} }
      '';
    }

    # --- THEME: CATPPUCCIN LIGHT (Latte) ---
    (lib.mkIf (cfg.style == "catppuccin_light") {
      colorschemes.catppuccin = {
        enable = true;
        settings.flavour = "latte";
      };
      # Latte base colour — avoids black notify background on a light theme
      plugins.notify.settings.backgroundColour = lib.mkForce "#eff1f5";
    })

    # --- THEME: CATPPUCCIN DARK (Mocha) ---
    (lib.mkIf (cfg.style == "catppuccin_dark") {
      colorschemes.catppuccin = {
        enable = true;
        settings.flavour = "mocha";
      };
    })

    # --- THEME: TOKYONIGHT (Moon) ---
    (lib.mkIf (cfg.style == "tokyonight") {
      colorschemes.tokyonight = {
        enable = true;
        settings = {
          style = "moon";
          transparent = true;
          terminal_colors = true;
          styles = {
            floats = "transparent";
            sidebars = "transparent";
          };
        };
      };
    })

    # --- THEME: AUTO (follows system appearance) ---
    (lib.mkIf (cfg.style == "auto") {
      colorschemes.catppuccin.enable = true;
      extraConfigLua = ''
        local function _is_dark_mode()
          if vim.fn.has("mac") == 1 then
            return vim.trim(vim.fn.system("defaults read -g AppleInterfaceStyle 2>/dev/null")) == "Dark"
          end
          -- Linux / GNOME
          return vim.fn.system("gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null"):find("dark") ~= nil
        end
        local _dark = _is_dark_mode()
        require("catppuccin").setup({ flavour = _dark and "mocha" or "latte" })
        vim.cmd("colorscheme catppuccin")
        -- Match notify background to the resolved theme so it looks correct on light
        require("notify").setup({ background_colour = _dark and "#000000" or "#eff1f5" })
      '';
    })

  ];
}
