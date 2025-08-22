gcmt() {
  emulate -L zsh -o pipefail

  # Farben
  local reset=$'\033[0m' yellow=$'\033[33m' green=$'\033[32m' red=$'\033[31m'

  # Flags & Args
  local -a args
  local flag_i=0 flag_c=0
  while (( $# )); do
    case "$1" in
      --) shift; break ;;
      -i|--interactive) flag_i=1 ;;
      -c|--conventional) flag_c=1 ;;
      -*)  # kombiniert kurz: -ci, -ic, etc.
        local grouped="${1#-}" ch
        for ch in ${(s::)grouped}; do
          case "$ch" in
            i) flag_i=1 ;;
            c) flag_c=1 ;;
            *) echo "${red}Unbekannte Option: -$ch${reset}"; return 2 ;;
          esac
        done
        ;;
      *) args+=("$1") ;;
    esac
    shift
  done
  (( $# )) && args+=("$@")

  # Branch lesen
  local branch detected_ticket project number
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || branch=''

  # Ticket / Sonderfall aus Branch
  if [[ $branch =~ '^[^/]+/([A-Za-z][A-Za-z0-9]+)-([0-9]+)' ]]; then
    project=${match[1]}
    number=${match[2]}
    detected_ticket="${project:u}-${number}"
  elif [[ $branch =~ '(^|/)(NOTICKET)(-|$)' ]]; then
    detected_ticket="NOTICKET"
  elif [[ $branch =~ '(^|/)(HOTFIX)(-|$)' ]]; then
    detected_ticket="HOTFIX"
  elif [[ $branch =~ '(^|/)(BUGFIX)(-|$)' ]]; then
    detected_ticket="BUGFIX"
  else
    detected_ticket=""
  fi

  # Picker Helper
  _pick_one() {
    local prompt="$1"; shift
    local -a list; list=("$@")
    local choice=""
    if command -v fzf >/dev/null 2>&1; then
      choice=$(printf "%s\n" "${list[@]}" | fzf --prompt="$prompt" --height=40% --reverse)
    else
      echo "${yellow}${prompt}${reset}"
      local i=1
      for o in "${list[@]}"; do printf "  %d) %s\n" "$i" "$o"; ((i++)); done
      printf "${yellow}Nummer eingeben:${reset} "
      local n; IFS= read -r n
      if [[ ! $n =~ '^[0-9]+$' ]] || (( n < 1 || n > ${#list[@]} )); then
        echo "${red}❌ Ungültige Auswahl.${reset}"; return 10
      fi
      choice="${list[$((n-1))]}"
    fi
    [[ -z $choice ]] && return 11
    print -r -- "$choice"
    return 0
  }

  # Interaktive Auswahl gemäß Flags (genau EIN Prefix)
  local chosen_prefix=""
  if (( flag_i || flag_c )); then
    local -a opts
    local -A seen
    if (( flag_i )); then
      [[ -n $detected_ticket && -z ${seen[$detected_ticket]} ]] && { opts+=("$detected_ticket"); seen[$detected_ticket]=1; }
      for p in NOTICKET HOTFIX BUGFIX; do
        [[ -z ${seen[$p]} ]] && { opts+=("$p"); seen[$p]=1; }
      done
      opts+=("CUSTOM" "NONE")
    fi
    if (( flag_c )); then
      local -a cc_opts=(feat fix docs style refactor perf test build ci chore revert)
      for p in "${cc_opts[@]}"; do
        [[ -z ${seen[$p]} ]] && { opts+=("$p"); seen[$p]=1; }
      done
    fi
    (( ${#opts[@]} == 0 )) && opts=("NONE")

    chosen_prefix=$(_pick_one "prefix> " "${opts[@]}") || { echo "${red}❌ Abgebrochen.${reset}"; return 1; }

    if [[ $chosen_prefix == "CUSTOM" ]]; then
      printf "${yellow}Custom Prefix (z.B. MP-999 oder DOCS): ${reset}"
      IFS= read -r chosen_prefix
      [[ -z ${chosen_prefix// } ]] && chosen_prefix="NONE"
    fi
  fi

  # Effektiven Prefix bestimmen
  local effective_prefix=""
  if (( flag_i || flag_c )); then
    [[ $chosen_prefix != "NONE" ]] && effective_prefix="$chosen_prefix" || effective_prefix=""
  else
    effective_prefix="$detected_ticket"
  fi

  # Message erfragen/setzen
  local msg prefix
  if (( ${#args[@]} == 0 )); then
    [[ -n $effective_prefix ]] && prefix="${effective_prefix}: " || prefix="Message: "
    printf "${yellow}%s${reset}" "$prefix"
    IFS= read -r msg
  else
    msg="${(j: :)args}"
  fi

  # Erst Duplikat-Prefix aus der Eingabe strippen (case-insensitive)
  if [[ -n $effective_prefix ]]; then
    local lower_msg="${(L)msg}" lower_eff="${(L)effective_prefix}"
    if [[ $lower_msg == ${lower_eff}:* || $lower_msg == ${lower_eff}\ * ]]; then
      msg="${msg#*: }"
    fi
  fi

  # Danach auf leere Message prüfen – IMMER abbrechen, wenn leer
  local trimmed="${${msg%%[[:space:]]#}##[[:space:]]#}"
  if [[ -z $trimmed ]]; then
    echo "${red}❌ Abgebrochen: leere Message.${reset}"
    return 1
  fi

  # Final bauen
  local final_msg
  if [[ -n $effective_prefix ]]; then
    final_msg="${effective_prefix}: ${msg}"
  else
    final_msg="${msg}"
  fi

  echo "${green}✅ Committing:${reset} $final_msg"
  git commit -m "$final_msg"
}
