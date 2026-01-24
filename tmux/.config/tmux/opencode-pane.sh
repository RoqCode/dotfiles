#!/usr/bin/env bash
set -euo pipefail

project_dir="${1:-$(pwd)}"

hash=$(printf "%s" "$project_dir" | cksum | awk '{print $1}')
port=$((4000 + (hash % 2000)))
option="@opencode_pane_${hash}"
allow_passthrough_option="@opencode_allow_passthrough_prev"

pane_id=$(tmux show-option -gqv "$option")
if [ -n "$pane_id" ]; then
  if tmux list-panes -a -F '#{pane_id}' | grep -qx "$pane_id"; then
    tmux kill-pane -t "$pane_id"
    tmux set-option -gu "$option"
    if ! tmux list-panes -a -F '#{pane_current_command}' | grep -qx "opencode"; then
      prev_allow_passthrough=$(tmux show-option -gqv "$allow_passthrough_option")
      if [ -n "$prev_allow_passthrough" ]; then
        tmux set-option -g allow-passthrough "$prev_allow_passthrough"
        tmux set-option -gu "$allow_passthrough_option"
      fi
    fi
    exit 0
  else
    tmux set-option -gu "$option"
  fi
fi

if [ -z "$(tmux show-option -gqv "$allow_passthrough_option")" ]; then
  current_allow_passthrough=$(tmux show-option -gqv allow-passthrough || true)
  tmux set-option -g "$allow_passthrough_option" "${current_allow_passthrough:-off}"
fi
tmux set-option -g allow-passthrough off

new_pane_id=$(tmux split-window -h -p 25 -c "$project_dir" -d -P -F '#{pane_id}' "env OPENCODE_DISABLE_TERMINAL_TITLE=1 opencode --port $port")
tmux set-option -g "$option" "$new_pane_id"
