unalias gd 2>/dev/null
unset -f gd 2>/dev/null

gd() {
  emulate -L zsh -o pipefail
  setopt localoptions

  local help_mode="false"
  local range=""

  while (( $# )); do
    case "$1" in
      -D) range="origin/develop...HEAD" ;;
      -M) range="origin/main...HEAD" ;;
      --range)
        shift
        range="$1"
        ;;
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
    echo "  --range <range>  Diff vs custom git range (e.g. origin/develop...HEAD)"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  gd"
    echo "  gd -D"
    echo "  gd -M"
    echo "  gd --range HEAD~3..HEAD"
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

  if [ -n "$range" ]; then
    nvim -c "DiffviewOpen $range"
  else
    nvim -c "DiffviewOpen"
  fi
}
