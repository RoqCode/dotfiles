gcmt() {
  emulate -L zsh -o pipefail
  setopt localoptions

  # Farben
  local reset=$'\033[0m' yellow=$'\033[33m' green=$'\033[32m' red=$'\033[31m' purple=$'\033[35m'

  # --- Flags & Args ---
  local -a args
  local flag_i=0 flag_c=0 flag_a=0
  while (( $# )); do
    case "$1" in
      --) shift; break ;;
      -i|--interactive) flag_i=1 ;;
      -c|--conventional) flag_c=1 ;;
      -a) flag_a=1 ;;
      -*)  # kombinierte Kurzflags wie -cia
        local grouped="${1#-}" ch
        for ch in ${(s::)grouped}; do
          case "$ch" in
            i) flag_i=1 ;;
            c) flag_c=1 ;;
            a) flag_a=1 ;;
            *) echo "${red}Unbekannte Option: -$ch${reset}"; return 2 ;;
          esac
        done
        ;;
      *) args+=("$1") ;;
    esac
    shift
  done
  (( $# )) && args+=("$@")

  # --- Branch lesen & Ticket erkennen ---
  local branch detected_ticket project number
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || branch=''

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

  # --- Picker Helper ---
  _pick_one() {
    local prompt_label="$1"; shift
    local -a list; list=("$@")
    local choice=""
    if command -v fzf >/dev/null 2>&1; then
      choice=$(printf "%s\n" "${list[@]}" | fzf --prompt="$prompt_label" --height=40% --reverse)
    else
      echo "${yellow}${prompt_label}${reset}"
      local i=1; for o in "${list[@]}"; do printf "  %d) %s\n" "$i" "$o"; ((i++)); done
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

  # --- Interaktive Prefix-Auswahl ---
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

  # --- Effektiver Prefix ---
  local effective_prefix=""
  if (( flag_i || flag_c )); then
    [[ $chosen_prefix != "NONE" ]] && effective_prefix="$chosen_prefix" || effective_prefix=""
  else
    effective_prefix="$detected_ticket"
  fi

  # --- Eingabe + Prüf-Loop ---
  local msg final_msg lower_msg lower_eff trimmed n
  while true; do
    if (( ${#args[@]} == 0 )); then
      if [[ -n $effective_prefix ]]; then
        printf "${yellow}%s: ${reset}" "$effective_prefix"
      else
        printf "${yellow}Message: ${reset}"
      fi
      IFS= read -r msg
    else
      msg="${(j: :)args}"
      args=()
    fi

    if [[ -n $effective_prefix ]]; then
      lower_msg="${(L)msg}" ; lower_eff="${(L)effective_prefix}"
      if [[ $lower_msg == ${lower_eff}:* || $lower_msg == ${lower_eff}\ * ]]; then
        msg="${msg#*: }"
      fi
    fi

    trimmed="${${msg%%[[:space:]]#}##[[:space:]]#}"
    if [[ -z $trimmed ]]; then
      echo "${red}❌ Abgebrochen: leere Message.${reset}"
      return 1
    fi

    if [[ -n $effective_prefix ]]; then
      final_msg="${effective_prefix}: ${msg}"
    else
      final_msg="${msg}"
    fi

    n=${#final_msg}
    if (( n > 72 )); then
      echo "${purple}⚠︎ Länge über 72 Zeichen!${reset} Länge ${n}"
      printf "${yellow}Trotzdem committen?${reset} (y=yes, n=no, e=edit) "
      local ans; read -rs -k1 ans; echo
      case "${ans:l}" in
        y) break ;;
        n|'') echo "${red}❌ Abgebrochen.${reset}"; return 1 ;;
        e) continue ;;
        *) echo "${red}❌ Abgebrochen.${reset}"; return 1 ;;
      esac
    else
      break
    fi
  done

  # --- Commit ausführen ---
  if (( flag_a )); then
    echo "${green}✅ Committing (with -a):${reset} $final_msg"
    git commit -am "$final_msg"
  else
    echo "${green}✅ Committing:${reset} $final_msg"
    git commit -m "$final_msg"
  fi
}
