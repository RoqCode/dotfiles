unalias gd 2>/dev/null
unset -f gd 2>/dev/null

gd() {
  emulate -L zsh -o pipefail
  setopt localoptions

  local help_mode="false"
  local range=""
  local last_count=""
  local review_mode="false"

  while (( $# )); do
    case "$1" in
      -D) range="origin/develop...HEAD" ;;
      -M) range="origin/main...HEAD" ;;
      --range)
        shift
        range="$1"
        ;;
      --last|-l)
        last_count="1"
        if (( $# > 1 )); then
          if [[ "$2" == <-> ]]; then
            last_count="$2"
            shift
          elif [[ "$2" != -* ]]; then
            echo "❌ --last expects a positive integer (e.g. --last 2)"
            return 1
          fi
        fi

        if [[ "$last_count" != <-> || "$last_count" -lt 1 ]]; then
          echo "❌ --last expects a positive integer (>= 1)"
          return 1
        fi

        range="HEAD~${last_count}..HEAD"
        ;;
      --review|-r) review_mode="true" ;;
      -h|--help) help_mode="true" ;;
      --) shift; break ;;
      *) ;;
    esac
    shift
  done

  if [ "$help_mode" = "true" ]; then
    echo "Usage: gd [options]"
    echo ""
    echo "Open Diffview in Neovim. Defaults to working tree vs index."
    echo ""
    echo "Options:"
    echo "  -D               Diff vs origin/develop"
    echo "  -M               Diff vs origin/main"
    echo "  -l, --last [n]   Diff HEAD~n..HEAD (default: n=1)"
    echo "  --range <range>  Diff vs custom git range (e.g. origin/develop...HEAD)"
    echo "  -r, --review     Open AI review layout (diffview + opencode)"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  gd"
    echo "  gd -D"
    echo "  gd -M"
    echo "  gd --last"
    echo "  gd --last 2"
    echo "  gd --range HEAD~3..HEAD"
    echo "  gd --review -D"
    echo "  gd -r -l 3"
    return
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "❌ Not inside a git repo."
    return 1
  fi

  if [ "$range" = "origin/develop...HEAD" ]; then
    if ! git show-ref --verify --quiet refs/remotes/origin/develop; then
      echo "❌ Remote branch not found: origin/develop"
      return 1
    fi
  fi

  if [ "$range" = "origin/main...HEAD" ]; then
    if ! git show-ref --verify --quiet refs/remotes/origin/main; then
      echo "❌ Remote branch not found: origin/main"
      return 1
    fi
  fi

  if [ -n "$last_count" ]; then
    if ! git rev-parse --verify --quiet "HEAD~${last_count}^{commit}" >/dev/null; then
      echo "❌ Commit range not found: HEAD~${last_count}..HEAD"
      return 1
    fi
  fi

  if [ "$review_mode" = "true" ]; then
    if [ -z "${TMUX:-}" ]; then
      echo "❌ --review requires an active tmux session."
      echo "   Start tmux first, then run: gd -r [other options]"
      return 1
    fi

    if ! command -v tmux >/dev/null 2>&1; then
      echo "❌ tmux is not installed or not in PATH."
      return 1
    fi

    ~/.config/tmux/review-layout.sh "$range" "$(pwd)"
  elif [ -n "$range" ]; then
    nvim -c "DiffviewOpen $range"
  else
    nvim -c "DiffviewOpen"
  fi
}
