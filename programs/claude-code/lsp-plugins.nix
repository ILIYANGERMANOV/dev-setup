# Official claude-plugins-official LSP plugins to enable globally.
# Each entry maps to a plugin in the Anthropic marketplace; the binary
# for that plugin must already be on PATH (managed separately via Home Manager).
{
  enabled = {
    "typescript-lsp@claude-plugins-official" = true;
  };

  # Loaded only during web UI sessions via `claude-web`. Stripped on normal `claude` launch.
  webUI = {
    "frontend-design@claude-plugins-official" = true;
  };
}
