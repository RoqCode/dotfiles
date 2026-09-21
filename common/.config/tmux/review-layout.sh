#!/usr/bin/env bash
set -uo pipefail

range="${1:-}"
project_dir="${2:-$(tmux display-message -p '#{pane_current_path}')}"
mason_bin="$HOME/.local/share/nvim/mason/bin"
opencode_env_path="$mason_bin:$PATH"
review_command_path="$HOME/.config/opencode/commands/review.md"

current_pane="$(tmux display-message -p '#{pane_id}')"

# Extract the command body so the TUI receives the command prompt, not /review as text.
if [[ ! -r "$review_command_path" ]]; then
  printf 'Review command not found: %s\n' "$review_command_path" >&2
  exit 1
fi

oc_prompt=""
frontmatter_delimiters=0
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" == "---" ]]; then
    ((frontmatter_delimiters += 1))
    continue
  fi

  if (( frontmatter_delimiters >= 2 )); then
    if [[ -n "$oc_prompt" ]]; then
      oc_prompt+=$'\n'
    fi
    oc_prompt+="$line"
  fi
done < "$review_command_path"

if (( frontmatter_delimiters < 2 )) || [[ -z "$oc_prompt" ]]; then
  printf 'Invalid review command: %s\n' "$review_command_path" >&2
  exit 1
fi

# Substitute the custom command placeholder before passing the prompt to OpenCode.
oc_prompt="${oc_prompt//\$ARGUMENTS/$range}"
printf -v quoted_oc_prompt '%q' "$oc_prompt"

# Build commands depending on whether a range was given.
if [ -n "$range" ]; then
  nvim_cmd="nvim -c 'DiffviewOpen $range'"
else
  nvim_cmd="nvim -c 'DiffviewOpen'"
fi

# Bottom pane: opencode (~40%)
tmux split-window -v -p 40 -t "$current_pane" -c "$project_dir" \
  "env PATH=\"$opencode_env_path\" OPENCODE_EXPERIMENTAL_LSP_TOOL=true opencode --agent review-lead --prompt $quoted_oc_prompt"

# Top pane: nvim + diffview (the original pane, now ~60%)
tmux send-keys -t "$current_pane" "$nvim_cmd" C-m

# Focus the top (diffview) pane
tmux select-pane -t "$current_pane"
