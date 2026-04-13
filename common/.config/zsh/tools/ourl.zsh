unalias ourl 2>/dev/null
unset -f ourl 2>/dev/null

ourl() {
  emulate -L zsh -o pipefail
  setopt localoptions

  # Colors
  local reset=$'\033[0m' yellow=$'\033[33m' green=$'\033[32m' red=$'\033[31m'

  # --- Flags ---
  local lines=50 flag_a=0 flag_h=0
  while (( $# )); do
    case "$1" in
      -n)
        shift
        if [[ -z $1 || ! $1 =~ '^[0-9]+$' ]]; then
          echo "${red}Error: -n requires a number${reset}"
          return 2
        fi
        lines="$1"
        ;;
      -a|--all)   flag_a=1 ;;
      -h|--help)  flag_h=1 ;;
      *)
        echo "${red}Unknown option: $1${reset}"
        return 2
        ;;
    esac
    shift
  done

  if (( flag_h )); then
    echo "Usage: ourl [options]"
    echo ""
    echo "Extract URLs from tmux scrollback or piped input and open them."
    echo ""
    echo "Options:"
    echo "  -n N      Number of scrollback lines to read (default: 50)"
    echo "  -a        Show all found URLs (default: only unique, newest first)"
    echo "  -h        Show this help message"
    echo ""
    echo "Examples:"
    echo "  ourl                  # parse last 50 lines of tmux scrollback"
    echo "  ourl -n 200           # parse last 200 lines"
    echo "  git push 2>&1 | ourl  # parse piped input"
    return
  fi

  # --- Read input ---
  local input=""
  if [[ ! -t 0 ]]; then
    # Pipe input
    input=$(</dev/stdin)
  elif [[ -n $TMUX ]]; then
    # tmux scrollback
    input=$(tmux capture-pane -pJ -S "-${lines}" 2>/dev/null)
    if [[ -z $input ]]; then
      echo "${red}Error: Failed to capture tmux pane.${reset}"
      return 1
    fi
  else
    echo "${red}Error: Not in tmux and no pipe input.${reset}"
    echo "${yellow}Usage: ourl  (inside tmux)  or  command | ourl${reset}"
    return 1
  fi

  # --- Parse URLs ---
  local -a urls=()
  local -A seen
  local line match_url
  local url_re="https://[^[:space:]<>\"{}|\\\`]+"

  # Read lines in reverse so newest URLs come first
  local -a input_lines
  input_lines=("${(@f)input}")
  local i
  for (( i=${#input_lines[@]}; i>=1; i-- )); do
    line="${input_lines[$i]}"
    # Extract all https:// URLs from the line
    while [[ $line =~ $url_re ]]; do
      match_url="${MATCH}"
      # Strip trailing punctuation that's likely not part of the URL
      match_url="${match_url%%[.,;:\!\)\'\"]}"
      if [[ -z ${seen[$match_url]} ]]; then
        urls+=("$match_url")
        seen[$match_url]=1
      fi
      # Remove matched portion to find additional URLs in same line
      line="${line#*$MATCH}"
    done
  done

  if (( ${#urls[@]} == 0 )); then
    echo "${red}No URLs found in last ${lines} lines.${reset}"
    return 1
  fi

  # --- Select URL ---
  local selected=""
  if (( ${#urls[@]} == 1 )); then
    selected="${urls[1]}"
  else
    # Multiple URLs found -- interactive input via /dev/tty so piping works
    if command -v fzf >/dev/null 2>&1; then
      selected=$(printf "%s\n" "${urls[@]}" | fzf --prompt="URL> " --height=40% --reverse)
    else
      echo "${yellow}URLs found:${reset}"
      local idx=1
      for u in "${urls[@]}"; do
        printf "  %d) %s\n" "$idx" "$u"
        ((idx++))
      done
      printf "${yellow}Select number:${reset} "
      local n
      IFS= read -r n < /dev/tty
      if [[ ! $n =~ '^[0-9]+$' ]] || (( n < 1 || n > ${#urls[@]} )); then
        echo "${red}Invalid selection.${reset}"
        return 1
      fi
      selected="${urls[$n]}"
    fi
  fi

  [[ -z $selected ]] && { echo "${red}Canceled.${reset}"; return 1; }

  # --- Confirm & open ---
  printf "${yellow}Open?${reset} %s ${yellow}[Y/n]${reset} " "$selected"
  local ans
  IFS= read -r ans < /dev/tty
  case "${ans:l}" in
    ""|y|yes)
      if command -v open >/dev/null 2>&1; then
        open "$selected" >/dev/null 2>&1
      elif command -v xdg-open >/dev/null 2>&1; then
        (xdg-open "$selected" &) >/dev/null 2>&1
      else
        echo "${red}No opener found. URL:${reset} $selected"
        return 1
      fi
      echo "${green}Opened.${reset}"
      ;;
    *)
      echo "${yellow}Skipped.${reset}"
      ;;
  esac
}
