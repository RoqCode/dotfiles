#!/usr/bin/env bash
set -uo pipefail

project_dir="${1:-$(tmux display-message -p '#{pane_current_path}')}"
window_id="$(tmux display-message -p '#{window_id}')"
current_pane="$(tmux display-message -p '#{pane_id}')"

enabled_option='@nuxt_logs_enabled'
raw_option='@nuxt_logs_raw_pane'
errors_option='@nuxt_logs_errors_pane'
requests_option='@nuxt_logs_requests_pane'
debug_option='@nuxt_logs_debug_pane'
legacy_noise_option='@nuxt_logs_noise_pane'

debug_prefix='[NUXT_DEBUG]'

log_dir="$project_dir/.tmux-logs"
log_file="$log_dir/nuxt-dev.log"

pane_exists() {
  local pane_id="$1"
  [ -n "$pane_id" ] && tmux list-panes -a -F '#{pane_id}' | grep -qx "$pane_id"
}

window_option() {
  local name="$1"
  tmux show-option -wqv -t "$window_id" "$name"
}

window_option_unset() {
  local name="$1"
  tmux set-option -wu -t "$window_id" "$name"
}

disable_layout() {
  local raw_pane errors_pane requests_pane debug_pane legacy_noise_pane

  raw_pane="$(window_option "$raw_option")"
  errors_pane="$(window_option "$errors_option")"
  requests_pane="$(window_option "$requests_option")"
  debug_pane="$(window_option "$debug_option")"
  legacy_noise_pane="$(window_option "$legacy_noise_option")"

  if pane_exists "$raw_pane"; then
    tmux pipe-pane -t "$raw_pane"
    tmux send-keys -t "$raw_pane" C-c
  fi

  if pane_exists "$errors_pane"; then
    tmux kill-pane -t "$errors_pane"
  fi
  if pane_exists "$requests_pane"; then
    tmux kill-pane -t "$requests_pane"
  fi
  if pane_exists "$debug_pane"; then
    tmux kill-pane -t "$debug_pane"
  fi
  if pane_exists "$legacy_noise_pane"; then
    tmux kill-pane -t "$legacy_noise_pane"
  fi

  if pane_exists "$raw_pane"; then
    tmux send-keys -t "$raw_pane" C-c
    tmux send-keys -t "$raw_pane" 'clear' C-m
    tmux select-pane -t "$raw_pane"
  elif pane_exists "$current_pane"; then
    tmux select-pane -t "$current_pane"
  fi

  window_option_unset "$enabled_option"
  window_option_unset "$raw_option"
  window_option_unset "$errors_option"
  window_option_unset "$requests_option"
  window_option_unset "$debug_option"
  window_option_unset "$legacy_noise_option"

  tmux display-message "Nuxt logs layout disabled"
}

if [ "$(window_option "$enabled_option")" = "1" ]; then
  disable_layout
  exit 0
fi

if ! pane_exists "$current_pane"; then
  tmux display-message "No active pane found"
  exit 1
fi

tmux send-keys -t "$current_pane" C-c

tmux send-keys -t "$current_pane" "mkdir -p \"$log_dir\" && : > \"$log_file\"" C-m
tmux pipe-pane -o -t "$current_pane" "cat >> \"$log_file\""
tmux send-keys -t "$current_pane" "FORCE_COLOR=1 npm run dev" C-m

errors_cmd="touch \"$log_file\" && tail -n 200 -F \"$log_file\" | perl -ne 'BEGIN { \$| = 1 } \$raw = \$_; (\$plain = \$raw) =~ s/\\e\\[[0-9;]*[A-Za-z]//g; print \$raw if \$plain =~ /ERROR|Error|WARN|Warn|Warning|FATAL|Unhandled/;'"
requests_cmd="touch \"$log_file\" && tail -n 200 -F \"$log_file\" | perl -ne 'BEGIN { \$| = 1 } \$raw = \$_; (\$plain = \$raw) =~ s/\\e\\[[0-9;]*[A-Za-z]//g; if (\$plain =~ /^(\\[[^\\]]+\\]\\s+)(GET|POST|PUT|PATCH|DELETE|OPTIONS|HEAD)\\s+([0-9]{3})(\\s+.*)\$/) { \$color = \$3 >= 400 ? chr(27).q([31m) : (\$3 >= 300 ? chr(27).q([33m) : chr(27).q([32m)); print \$color.\$1.\$2.q( ).\$3.chr(27).q([0m).\$4.qq(\\n); }'"
debug_cmd="touch \"$log_file\" && tail -n 200 -F \"$log_file\" | NUXT_DEBUG_PREFIX=\"$debug_prefix\" perl -ne 'BEGIN { \$| = 1 } \$raw = \$_; (\$plain = \$raw) =~ s/\\e\\[[0-9;]*[A-Za-z]//g; if (index(\$plain, \$ENV{\"NUXT_DEBUG_PREFIX\"}) >= 0) { \$raw =~ s/\\Q\$ENV{\"NUXT_DEBUG_PREFIX\"}\\E/\\e[38;5;208m\$ENV{\"NUXT_DEBUG_PREFIX\"}\\e[0m/g; print \$raw; }'"

requests_pane="$(tmux split-window -h -p 67 -t "$current_pane" -c "$project_dir" -d -P -F '#{pane_id}' "$requests_cmd")"
debug_pane="$(tmux split-window -v -p 20 -t "$requests_pane" -c "$project_dir" -d -P -F '#{pane_id}' "$debug_cmd")"
errors_pane="$(tmux split-window -v -p 50 -t "$requests_pane" -c "$project_dir" -d -P -F '#{pane_id}' "$errors_cmd")"

tmux select-pane -t "$current_pane" -T "raw"
tmux select-pane -t "$errors_pane" -T "errors/warns"
tmux select-pane -t "$requests_pane" -T "requests"
tmux select-pane -t "$debug_pane" -T "debug"

tmux set-option -w -t "$window_id" "$enabled_option" 1
tmux set-option -w -t "$window_id" "$raw_option" "$current_pane"
tmux set-option -w -t "$window_id" "$errors_option" "$errors_pane"
tmux set-option -w -t "$window_id" "$requests_option" "$requests_pane"
tmux set-option -w -t "$window_id" "$debug_option" "$debug_pane"

tmux select-pane -t "$current_pane"
tmux display-message "Nuxt logs layout enabled (debug prefix: $debug_prefix)"
