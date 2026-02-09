unalias gc 2>/dev/null
unset -f gc 2>/dev/null

gc() {
  emulate -L zsh -o pipefail
  setopt localoptions

  # Colors
  local reset=$'\033[0m' yellow=$'\033[33m' green=$'\033[32m' red=$'\033[31m' purple=$'\033[35m'

  # --- Flags & Args ---
  local -a args
  local flag_i=0 flag_c=0 flag_a=0 flag_p=0 flag_no_open=0
  while (( $# )); do
    case "$1" in
      --) shift; break ;;
      -i|--interactive) flag_i=1 ;;
      -c|--conventional) flag_c=1 ;;
      -a) flag_a=1 ;;
      -p|--push) flag_p=1 ;;
      --no-open) flag_no_open=1 ;;
      -*)  # combined short flags like -cia
        local grouped="${1#-}" ch
        for ch in ${(s::)grouped}; do
          case "$ch" in
            i) flag_i=1 ;;
            c) flag_c=1 ;;
            a) flag_a=1 ;;
            p) flag_p=1 ;;
            *) echo "${red}Unknown option: -$ch${reset}"; return 2 ;;
          esac
        done
        ;;
      *) args+=("$1") ;;
    esac
    shift
  done
  (( $# )) && args+=("$@")

  # --- Read branch & detect ticket ---
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

  # --- Staged/Changes Check ---
  if (( flag_a )); then
    if [[ -z $(git status --porcelain) ]]; then
      echo "${red}❌ Nothing to commit (no changes).${reset}"
      return 1
    fi
  else
    if git diff --cached --quiet; then
      echo "${red}❌ Nothing staged. Please stage first.${reset}"
      return 1
    fi
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
       printf "${yellow}Enter number:${reset} "
      local n; IFS= read -r n
      if [[ ! $n =~ '^[0-9]+$' ]] || (( n < 1 || n > ${#list[@]} )); then
        echo "${red}❌ Invalid selection.${reset}"; return 10
      fi
      choice="${list[$((n-1))]}"
    fi
    [[ -z $choice ]] && return 11
    print -r -- "$choice"
    return 0
  }

  # --- Interactive prefix selection ---
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

      chosen_prefix=$(_pick_one "prefix> " "${opts[@]}") || { echo "${red}❌ Canceled.${reset}"; return 1; }
      if [[ $chosen_prefix == "CUSTOM" ]]; then
        if [[ -t 0 && -t 1 && -o interactive ]]; then
          vared -p "${yellow}Custom prefix (e.g. MP-999 or DOCS): ${reset}" chosen_prefix
        else
          printf "${yellow}Custom prefix (e.g. MP-999 or DOCS): ${reset}"
          IFS= read -r chosen_prefix
        fi
        [[ -z ${chosen_prefix// } ]] && chosen_prefix="NONE"
      fi
  fi

  # --- Effective prefix ---
  local effective_prefix=""
  if (( flag_i || flag_c )); then
    [[ $chosen_prefix != "NONE" ]] && effective_prefix="$chosen_prefix" || effective_prefix=""
  else
    effective_prefix="$detected_ticket"
  fi

  # --- Input + validation loop ---
  local msg final_msg lower_msg lower_eff trimmed n
  while true; do
    if (( ${#args[@]} == 0 )); then
      if [[ -n $effective_prefix ]]; then
        if [[ -t 0 && -t 1 && -o interactive ]]; then
          vared -p "${yellow}${effective_prefix}: ${reset}" msg
        else
          printf "${yellow}%s: ${reset}" "$effective_prefix"
          IFS= read -r msg
        fi
      else
        if [[ -t 0 && -t 1 && -o interactive ]]; then
          vared -p "${yellow}Message: ${reset}" msg
        else
          printf "${yellow}Message: ${reset}"
          IFS= read -r msg
        fi
      fi
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
      echo "${red}❌ Canceled: empty message.${reset}"
      return 1
    fi

    if [[ -n $effective_prefix ]]; then
      final_msg="${effective_prefix}: ${msg}"
    else
      final_msg="${msg}"
    fi

    n=${#final_msg}
      if (( n > 72 )); then
        echo "${purple}⚠︎ Length over 72 characters!${reset} Length ${n}"
        printf "${yellow}Commit anyway?${reset} (y=yes, n=no, e=edit) "
        local ans; read -rs -k1 ans; echo
        case "${ans:l}" in
          y) break ;;
          n|'') echo "${red}❌ Canceled.${reset}"; return 1 ;;
          e) continue ;;
          *) echo "${red}❌ Canceled.${reset}"; return 1 ;;
        esac
      else
        break
      fi
    done

    # --- Run commit ---
    if (( flag_a )); then
      echo "${green}✅ Staging all changes (with -a)${reset}"
      git add -A || return $?
      local -a staged_now
      staged_now=("${(@f)$(git diff --cached --name-status)}")
      if (( ${#staged_now[@]} )); then
        echo "${yellow}📦 Files to commit:${reset}"
        printf "  %s\n" "${staged_now[@]}"
      else
        echo "${red}❌ Nothing staged after git add -A.${reset}"
        return 1
      fi
      echo "${green}✅ Committing (with -a)${reset}: $final_msg"
      git commit -m "$final_msg"
    else
      echo "${green}✅ Committing${reset}: $final_msg"
      git commit -m "$final_msg"
    fi

    # --- Optional push ---
    if (( flag_p )); then
      local branch_name
      branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
      echo "${yellow}⬆️ Pushing branch '${branch_name}'...${reset}"
      local push_output push_status mr_url line
      push_output="$(git push 2>&1)"
      push_status=$?
      print -r -- "$push_output"
      (( push_status == 0 )) || return $push_status

      mr_url=""
      while IFS= read -r line; do
        if [[ $line =~ '(https://[^[:space:]]+/-/merge_requests/(new\?merge_request%5Bsource_branch%5D=[^[:space:]]+|[0-9]+))' ]]; then
          mr_url="${match[1]}"
          break
        fi
      done <<< "$push_output"

      if (( ! flag_no_open )) && [[ -n $mr_url && -t 0 && -t 1 && -o interactive ]]; then
        printf "${yellow}Open MR URL? [Y/n]${reset}\n"
        printf "  %s\n" "$mr_url"
        local open_ans
        IFS= read -r open_ans
        case "${open_ans:l}" in
          ""|y|yes)
            if command -v open >/dev/null 2>&1; then
              open "$mr_url" >/dev/null 2>&1
            elif command -v xdg-open >/dev/null 2>&1; then
              nohup xdg-open "$mr_url" >/dev/null 2>&1 &
            else
              echo "${yellow}No opener found; MR URL:${reset} $mr_url"
            fi
            ;;
          *)
            echo "${yellow}Skipped opening MR URL.${reset}"
            ;;
        esac
      fi
    fi
  }
