# fzf git branch search
gs() {
  local fetch_mode="false"
  local create_mode="false"
  local last_mode="false"
  local sync_mode="false"
  local help_mode="false"
  local source="remote"
  local query=""

  for arg in "$@"; do
    case "$arg" in
      --fetch|-f) fetch_mode="true" ;;
      --update|-U) fetch_mode="true"; sync_mode="true" ;;
      --create|-c) create_mode="true" ;;
      --last|-L) last_mode="true" ;;
      --sync|-u) sync_mode="true" ;;
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
    echo "  -U, --update         Fetch + fast-forward sync after switch (shortcut for -f -u)"
    echo "  -u, --sync           Fast-forward pull after switch when branch is behind"
    echo "  -l, --local          Use local branches instead of origin branches"
    echo "  -c, --create NAME    Create and switch to a new branch"
    echo "  -L, --last           Switch to the previously checked-out branch"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  gs"
    echo "  gs fix"
    echo "  gs -f"
    echo "  gs -U"
    echo "  gs -f -u"
    echo "  gs -l"
    echo "  gs -c feature/foo"
    echo "  gs -L"
    return
  fi

  sync_current_branch() {
    local upstream counts ahead behind

    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null) || {
      echo "ℹ️  No upstream set for current branch; skipping sync."
      return 0
    }

    counts=$(git rev-list --left-right --count HEAD..."$upstream" 2>/dev/null) || {
      echo "⚠️  Could not compare with upstream '$upstream'."
      return 0
    }

    IFS=$' \t' read -r ahead behind <<< "$counts"

    if [ "$behind" -gt 0 ] && [ "$ahead" -eq 0 ]; then
      echo "⬇️  Fast-forwarding from $upstream..."
      git pull --ff-only || echo "⚠️  Fast-forward pull failed."
    elif [ "$behind" -gt 0 ] && [ "$ahead" -gt 0 ]; then
      echo "⚠️  Branch diverged from $upstream (ahead $ahead, behind $behind); skipping auto-pull."
    elif [ "$ahead" -gt 0 ]; then
      echo "ℹ️  Branch is ahead of $upstream by $ahead commit(s); skipping auto-pull."
    else
      echo "✅ Branch is up to date with $upstream."
    fi
  }

  ping_switch_event() {
    local from_branch="$1"
    local to_branch="$2"
    if (( ${+functions[_day_project_scope]} && ${+functions[_day_ping]} )); then
      local _scope
      _scope="$(_day_project_scope)"
      _day_ping "gs" "branch-switch from ${from_branch} to ${to_branch}" "$_scope"
    fi
  }

  switch_branch() {
    local target="$1"
    local from_branch
    from_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    [ -z "$from_branch" ] && from_branch="HEAD"

    if git switch "$target" || git switch -c "$target" --track "origin/$target"; then
      if [ "$sync_mode" = "true" ]; then
        sync_current_branch
      fi
      local to_branch
      to_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
      [ -z "$to_branch" ] && to_branch="$target"
      ping_switch_event "$from_branch" "$to_branch"
      return 0
    fi

    echo "❌ Could not switch to '$target'."
    return 1
  }

  if [ "$fetch_mode" = "true" ]; then
    git fetch --prune
  fi

  if [ "$last_mode" = "true" ]; then
    echo "↩ Switching to previous branch..."
    local from_branch
    from_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    [ -z "$from_branch" ] && from_branch="HEAD"
    if git switch -; then
      if [ "$sync_mode" = "true" ]; then
        sync_current_branch
      fi
      local current_branch
      current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
      if [ -n "$current_branch" ]; then
        ping_switch_event "$from_branch" "$current_branch"
      fi
    else
      echo "❌ No previous branch found."
    fi
    return
  fi

  if [ "$create_mode" = "true" ]; then
    if [ -n "$query" ]; then
      local from_branch
      from_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
      [ -z "$from_branch" ] && from_branch="HEAD"
      if git switch -c "$query"; then
        local to_branch
        to_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        [ -z "$to_branch" ] && to_branch="$query"
        ping_switch_event "$from_branch" "$to_branch"
      else
        echo "❌ Could not create branch '$query'."
      fi
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
      switch_branch "$match"
      return
    fi
  fi

  local branch
  branch=$(printf "%s\n" "$branch_list" | fzf \
    --prompt="🌀 Select branch [$source]: " \
    --preview="$preview_cmd" \
    --preview-window=down:20%:wrap)

  if [ -n "$branch" ]; then
    switch_branch "$branch"
  else
    echo "🚫 No branch selected."
  fi
}
