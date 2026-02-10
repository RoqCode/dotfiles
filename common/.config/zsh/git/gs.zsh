# fzf git branch search
gs() {
  local fetch_mode="false"
  local create_mode="false"
  local last_mode="false"
  local help_mode="false"
  local source="remote"
  local query=""

  for arg in "$@"; do
    case "$arg" in
      --fetch|-f) fetch_mode="true" ;;
      --create|-c) create_mode="true" ;;
      --last|-L) last_mode="true" ;;
      --local|-l) source="local" ;;
      --help|-h) help_mode="true" ;;
      --*|-*) ;; # skip unknown flags
      *) query="$arg" ;;
    esac
  done

  if [ "$help_mode" = "true" ]; then
    echo "Usage: gs [options] [query]"
    echo ""
    echo "fzf branch switcher with optional auto-match and branch creation."
    echo ""
    echo "Options:"
    echo "  -f, --fetch          Fetch and prune remotes before listing branches"
    echo "  -l, --local          Use local branches instead of origin branches"
    echo "  -c, --create NAME    Create and switch to a new branch"
    echo "  -L, --last           Switch to the previously checked-out branch"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  gs"
    echo "  gs fix"
    echo "  gs -f"
    echo "  gs -l"
    echo "  gs -c feature/foo"
    echo "  gs -L"
    return
  fi

  if [ "$fetch_mode" = "true" ]; then
    git fetch --prune
  fi

  if [ "$last_mode" = "true" ]; then
    echo "↩ Switching to previous branch..."
    git switch - || echo "❌ No previous branch found."
    return
  fi

  if [ "$create_mode" = "true" ]; then
    if [ -n "$query" ]; then
      git switch -c "$query" || echo "❌ Could not create branch '$query'."
    else
      echo "❌ Please provide a branch name (e.g. gs -c feature/foo)."
    fi
    return
  fi

  local branch_list=""
  local preview_cmd=""
  if [ "$source" = "local" ]; then
    branch_list=$(git for-each-ref --format='%(refname:short)' refs/heads)
    preview_cmd='git log -5 --color=always --format="%C(bold yellow)%h%Creset %s%n%C(dim cyan)%an%Creset, %C(blue)%cr%Creset" {}'
  else
    branch_list=$(
      git for-each-ref --format='%(refname:short)' refs/remotes/origin \
        | grep -v '^origin/HEAD$' \
        | sed 's|^origin/||'
    )
    preview_cmd='git log -5 --color=always --format="%C(bold yellow)%h%Creset %s%n%C(dim cyan)%an%Creset, %C(blue)%cr%Creset" origin/{}'
  fi

  if [ -n "$query" ]; then
    local match
    match=$(printf "%s\n" "$branch_list" | grep -i -F -x "$query" | head -n 1)
    if [ -z "$match" ]; then
      match=$(printf "%s\n" "$branch_list" | grep -i -F "$query" | head -n 1)
    fi

    if [ -n "$match" ]; then
      echo "🔁 Auto-switching to: $match"
      git switch "$match" \
        || git switch -c "$match" --track "origin/$match" \
        || echo "❌ Could not switch to '$match'."
      return
    fi
  fi

  local branch
  branch=$(printf "%s\n" "$branch_list" | fzf \
    --prompt="🌀 Select branch [$source]: " \
    --preview="$preview_cmd" \
    --preview-window=down:20%:wrap)

  if [ -n "$branch" ]; then
    git switch "$branch" \
      || git switch -c "$branch" --track "origin/$branch" \
      || echo "❌ Could not switch to '$branch'."
  else
    echo "🚫 No branch selected."
  fi
}
