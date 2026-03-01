_day_current_branch() {
  emulate -L zsh
  setopt localoptions

  local branch
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || branch=""
  print -r -- "$branch"
}

_day_ticket_prefix() {
  emulate -L zsh
  setopt localoptions

  local branch project number lower
  branch="${1:-$(_day_current_branch)}"

  if [[ -z $branch ]]; then
    print -r -- ""
    return 0
  fi

  if [[ $branch =~ '^[^/]+/([A-Za-z][A-Za-z0-9]+)-([0-9]+)' ]]; then
    project=${match[1]}
    number=${match[2]}
    print -r -- "${project:u}-${number}"
    return 0
  fi

  lower="${branch:l}"

  if [[ $lower =~ '(^|/)(noticket)(-|$)' ]]; then
    print -r -- "NOTICKET"
    return 0
  fi

  if [[ $lower =~ '(^|/)(hotfix)(-|$)' ]]; then
    print -r -- "HOTFIX"
    return 0
  fi

  if [[ $lower =~ '(^|/)(bugfix)(-|$)' ]]; then
    print -r -- "BUGFIX"
    return 0
  fi

  print -r -- ""
}

_day_scope_suffix() {
  emulate -L zsh
  setopt localoptions

  local branch ticket
  branch="${1:-$(_day_current_branch)}"

  if [[ -z $branch ]]; then
    print -r -- ""
    return 0
  fi

  ticket="$(_day_ticket_prefix "$branch")"
  if [[ -n $ticket ]]; then
    print -r -- "$ticket"
    return 0
  fi

  print -r -- "$branch"
}

_day_repo_name() {
  emulate -L zsh
  setopt localoptions

  local root repo
  root=$(git rev-parse --show-toplevel 2>/dev/null) || root=""
  if [[ -z $root ]]; then
    print -r -- ""
    return 0
  fi

  repo=${root:t}
  print -r -- "$repo"
}

_day_project_scope() {
  emulate -L zsh
  setopt localoptions

  local repo suffix
  repo="${1:-$(_day_repo_name)}"
  suffix="${2:-$(_day_scope_suffix)}"

  if [[ -z $repo ]]; then
    print -r -- "$suffix"
    return 0
  fi

  if [[ -z $suffix ]]; then
    print -r -- "$repo"
    return 0
  fi

  print -r -- "${repo}/${suffix}"
}

# Backward compatibility for existing callers.
_day_branch_scope() {
  _day_scope_suffix "$@"
}

_day_ping() {
  emulate -L zsh
  setopt localoptions

  local source="$1"
  local activity="$2"
  local scope="$3"

  if ! command -v day >/dev/null 2>&1; then
    return 0
  fi

  if [[ -z $source ]]; then
    source="automation"
  fi

  if [[ -n $scope ]]; then
    day ping --silent --source "$source" "$activity" --scope "$scope" >/dev/null 2>&1 &!
  else
    day ping --silent --source "$source" "$activity" >/dev/null 2>&1 &!
  fi
}
