_: {
  programs.gitui = {
    enable = true;

    # ANSI terminal colors — adapts to Ghostty light/dark/auto theme
    theme = ''
      (
          selected_tab: Reset,
          command_fg: Reset,
          selection_bg: Some(Blue),
          selection_fg: Reset,
          cmdbar_bg: Reset,
          cmdbar_extra_lines_bg: Reset,
          disabled_fg: Some(DarkGray),
          diff_line_add: Some(Green),
          diff_line_delete: Some(Red),
          diff_file_added: Some(Cyan),
          diff_file_removed: Some(LightRed),
          diff_file_moved: Some(Magenta),
          diff_file_modified: Some(Yellow),
          commit_hash: Some(Magenta),
          commit_time: Some(Cyan),
          commit_author: Some(Green),
          danger_fg: Some(Red),
          push_gauge_bg: Some(Blue),
          push_gauge_fg: Reset,
          tag_fg: Some(Magenta),
          branch_fg: Some(Yellow),
      )
    '';
  };
}
