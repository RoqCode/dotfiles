# fzf git branch search
gs() {
  case "$*" in
    *--fetch*|*-f*) git fetch --prune ;;
  esac

  local source="remote"
  case "$*" in
    *--local*|*-l*) source="local" ;;
  esac

  local query=""
  for arg in "$@"; do
    case "$arg" in
      --*|-*) ;; # skip flags
      *) query="$arg" ;;
    esac
  done

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
      echo "🔁 Automatisch wechseln zu: $match"
      git switch "$match" \
        || git switch -c "$match" --track "origin/$match" \
        || echo "❌ Konnte nicht zu '$match' wechseln."
      return
    fi
  fi

  local branch
  branch=$(printf "%s\n" "$branch_list" | fzf \
    --prompt="🌀 Branch wählen [$source]: " \
    --preview="$preview_cmd" \
    --preview-window=down:20%:wrap)

  if [ -n "$branch" ]; then
    git switch "$branch" \
      || git switch -c "$branch" --track "origin/$branch" \
      || echo "❌ Konnte nicht zu '$branch' wechseln."
  else
    echo "🚫 Kein Branch ausgewählt."
  fi
}
