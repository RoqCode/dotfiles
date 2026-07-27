#!/usr/bin/env bash
set -uo pipefail

project_dir="${1:-$(pwd)}"
project_dir=$(git -C "$project_dir" rev-parse --show-toplevel 2>/dev/null || printf "%s" "$project_dir")

hash=$(printf "%s" "$project_dir" | cksum | awk '{print $1}')
port=$((20000 + (hash % 10000)))
option="@opencode_pane_${hash}"
mason_bin="$HOME/.local/share/nvim/mason/bin"
opencode_env_path="$mason_bin:$PATH"

join_to_current() {
  local source_pane_id="$1"
  local target_pane_id="$2"
  local target_window_id="$3"
  local window_width
  local pane_width

  window_width=$(tmux display-message -p '#{window_width}')
  pane_width=$((window_width * 25 / 100))
  if [ "$pane_width" -lt 40 ]; then
    pane_width=40
  fi

  if tmux join-pane -d -h -l "$pane_width" -s "$source_pane_id" -t "$target_pane_id" 2>/dev/null; then
    tmux select-pane -t "$source_pane_id"
    return 0
  fi
  if tmux join-pane -d -h -l "$pane_width" -s "$source_pane_id" -t "$target_window_id" 2>/dev/null; then
    tmux select-pane -t "$source_pane_id"
    return 0
  fi
  tmux select-window -t "$target_window_id" 2>/dev/null || true
}

pane_id=$(tmux show-option -gqv "$option")
if [ -n "$pane_id" ]; then
  if tmux list-panes -a -F '#{pane_id}' | grep -qx "$pane_id"; then
    current_window_id=$(tmux display-message -p '#{window_id}')
    current_pane_id=$(tmux display-message -p '#{pane_id}')
    pane_window_id=$(tmux list-panes -a -F '#{pane_id} #{window_id}' | awk -v id="$pane_id" '$1==id {print $2; exit}')
    if [ "$pane_window_id" = "$current_window_id" ]; then
      hidden_window_id=$(tmux break-pane -d -s "$pane_id" -P -F '#{window_id}')
      tmux rename-window -t "$hidden_window_id" "OC"
    else
      project_pane_id=$(tmux list-panes -a -F '#{pane_id}::#{pane_current_command}::#{pane_current_path}::#{window_id}' | awk -F '::' -v path="$project_dir" '$2=="opencode" && $3==path {print $1":"$4; exit}')
      if [ -n "$project_pane_id" ]; then
        pane_id=$(printf "%s" "$project_pane_id" | cut -d ':' -f 1)
        pane_window_id=$(printf "%s" "$project_pane_id" | cut -d ':' -f 2)
      fi
      if [ -n "$pane_id" ]; then
        if [ "$pane_window_id" = "$current_window_id" ]; then
          tmux select-pane -t "$pane_id"
        else
          join_to_current "$pane_id" "$current_pane_id" "$current_window_id"
        fi
      fi
    fi
    exit 0
  else
    tmux set-option -gu "$option"
  fi
fi

existing_pane_id=$(tmux list-panes -a -F '#{pane_id}::#{pane_current_command}::#{pane_current_path}::#{window_id}' | awk -F '::' -v path="$project_dir" '$2=="opencode" && $3==path {print $1":"$4; exit}')
if [ -n "$existing_pane_id" ]; then
  pane_id=$(printf "%s" "$existing_pane_id" | cut -d ':' -f 1)
  pane_window_id=$(printf "%s" "$existing_pane_id" | cut -d ':' -f 2)
  current_window_id=$(tmux display-message -p '#{window_id}')
  current_pane_id=$(tmux display-message -p '#{pane_id}')
  if [ "$pane_window_id" = "$current_window_id" ]; then
    tmux select-pane -t "$pane_id"
  else
    join_to_current "$pane_id" "$current_pane_id" "$current_window_id"
  fi
  tmux set-option -g "$option" "$pane_id"
  exit 0
fi

window_width=$(tmux display-message -p '#{window_width}')
pane_width=$((window_width * 25 / 100))
if [ "$pane_width" -lt 40 ]; then
  pane_width=40
fi

new_pane_id=$(tmux split-window -h -l "$pane_width" -c "$project_dir" -d -P -F '#{pane_id}' "env PATH=\"$opencode_env_path\" OPENCODE_EXPERIMENTAL_LSP_TOOL=true OPENCODE_DISABLE_TERMINAL_TITLE=1 opencode --agent plan --port $port")
tmux set-option -g "$option" "$new_pane_id"
tmux select-pane -t "$new_pane_id"
