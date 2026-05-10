{ pkgs, theme ? "auto", ... }:

let
  statusline = import ./statusline.nix { inherit pkgs theme; };
  lspPlugins = import ./lsp-plugins.nix;

  webUIKeys = builtins.attrNames lspPlugins.webUI;

  # MCP servers injected only for web UI sessions. Stripped on normal `claude` launch.
  # FIGMA_API_KEY must be set in the environment (e.g. in ~/.zshrc or a secrets manager).
  figmaMcp = {
    type = "stdio";
    command = "npx";
    args = [ "-y" "figma-developer-mcp" "--stdio" ];
  };

  # Merges managed keys into ~/.claude/settings.json, preserving user-set values.
  # Also strips webUI plugins and MCPs so HM activation always restores a clean baseline.
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
        --argjson webUIKeys '${builtins.toJSON webUIKeys}' \
        '. + {statusLine: {type: "command", command: $cmd}, autoMemoryEnabled: false, effortLevel: "medium"}
         | .enabledPlugins = ((.enabledPlugins // {}) + $lsp | with_entries(select(.key as $k | $webUIKeys | index($k) | not)))
         | del(.mcpServers.figma)' \
        "$settings_file" > "$tmp" && mv "$tmp" "$settings_file"
    '';
  };

  # Normal claude: strips webUI plugins and MCPs then launches.
  # Self-healing: fixes any stuck state left by a force-killed claude-web.
  claudeBase = pkgs.writeShellApplication {
    name = "claude";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      settings_file="$HOME/.claude/settings.json"
      if [ -f "$settings_file" ]; then
        tmp=$(mktemp)
        jq --argjson webUIKeys '${builtins.toJSON webUIKeys}' \
          '.enabledPlugins = (.enabledPlugins // {} | with_entries(select(.key as $k | $webUIKeys | index($k) | not)))
           | del(.mcpServers.figma)' \
          "$settings_file" > "$tmp" && mv "$tmp" "$settings_file"
      fi
      exec ${pkgs.claude-code}/bin/claude "$@"
    '';
  };

  # Web UI claude: injects webUI plugins and Figma MCP then launches.
  # Force-kill safe: the next normal `claude` invocation strips them automatically.
  # Requires FIGMA_API_KEY to be set in the environment; skips MCP injection if absent.
  claudeWeb = pkgs.writeShellApplication {
    name = "claude-web";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      settings_file="$HOME/.claude/settings.json"
      mkdir -p "$(dirname "$settings_file")"
      [ ! -f "$settings_file" ] && printf '{}' > "$settings_file"
      tmp=$(mktemp)

      figma_key="''${FIGMA_API_KEY:-}"
      if [ -n "$figma_key" ]; then
        jq --argjson web '${builtins.toJSON lspPlugins.webUI}' \
          --argjson mcp '${builtins.toJSON figmaMcp}' \
          --arg key "$figma_key" \
          '.enabledPlugins = ((.enabledPlugins // {}) + $web)
           | .mcpServers = ((.mcpServers // {}) + {figma: ($mcp + {env: {FIGMA_API_KEY: $key}})})' \
          "$settings_file" > "$tmp" && mv "$tmp" "$settings_file"
      else
        jq --argjson web '${builtins.toJSON lspPlugins.webUI}' \
          '.enabledPlugins = ((.enabledPlugins // {}) + $web)' \
          "$settings_file" > "$tmp" && mv "$tmp" "$settings_file"
      fi

      exec ${pkgs.claude-code}/bin/claude "$@"
    '';
  };

in
{
  inherit statusline settingsMerge claudeBase claudeWeb;

  # Raw package, useful for shells and other consumers that need the binary directly.
  package = pkgs.claude-code;

  # All packages needed to use Claude Code in a shell or home environment.
  packages = [ claudeBase claudeWeb statusline settingsMerge ];

  # Ready-to-use string for home.activation or shellHook.
  activationScript = "${settingsMerge}/bin/claude-settings-merge \"${statusline}/bin/claude-statusline\"";
}
