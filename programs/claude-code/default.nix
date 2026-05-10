{ pkgs, theme ? "auto", ... }:

let
  statusline = import ./statusline.nix { inherit pkgs theme; };
  lspPlugins = import ./lsp-plugins.nix;

  # Merges managed keys into ~/.claude/settings.json, preserving user-set values.
  settingsMerge = pkgs.writeShellApplication {
    name = "claude-settings-merge";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      statusline_cmd="''${1:-}"
      settings_file="$HOME/.claude/settings.json"
      mkdir -p "$(dirname "$settings_file")"
      [ ! -f "$settings_file" ] && printf '{}' > "$settings_file"
      tmp=$(mktemp)
      jq --arg cmd "$statusline_cmd" \
        --argjson lsp '${builtins.toJSON lspPlugins.enabled}' \
        '. + {statusLine: {type: "command", command: $cmd}, autoMemoryEnabled: false, effortLevel: "medium"}
         | .enabledPlugins = ((.enabledPlugins // {}) + $lsp)' \
        "$settings_file" > "$tmp" && mv "$tmp" "$settings_file"
    '';
  };

in
{
  inherit statusline settingsMerge;

  package = pkgs.claude-code;

  # All packages needed to use Claude Code in a shell or home environment.
  packages = [ pkgs.claude-code statusline settingsMerge ];

  # Ready-to-use string for home.activation or shellHook.
  activationScript = "${settingsMerge}/bin/claude-settings-merge \"${statusline}/bin/claude-statusline\"";
}
