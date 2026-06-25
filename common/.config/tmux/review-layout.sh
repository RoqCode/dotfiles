#!/usr/bin/env bash
set -uo pipefail

range="${1:-}"
project_dir="${2:-$(tmux display-message -p '#{pane_current_path}')}"
mason_bin="$HOME/.local/share/nvim/mason/bin"
opencode_env_path="$mason_bin:$PATH"

current_pane="$(tmux display-message -p '#{pane_id}')"

# Build commands depending on whether a range was given
if [ -n "$range" ]; then
  nvim_cmd="nvim -c 'DiffviewOpen $range'"
  oc_prompt="/review $range"
else
  nvim_cmd="nvim -c 'DiffviewOpen'"
  oc_prompt="/review"
fi

# Bottom pane: opencode (~40%)
tmux split-window -v -p 40 -t "$current_pane" -c "$project_dir" \
  "env PATH=\"$opencode_env_path\" OPENCODE_EXPERIMENTAL_LSP_TOOL=true opencode --agent plan --prompt '$oc_prompt'"

# Top pane: nvim + diffview (the original pane, now ~60%)
tmux send-keys -t "$current_pane" "$nvim_cmd" C-m

# Focus the top (diffview) pane
tmux select-pane -t "$current_pane"
