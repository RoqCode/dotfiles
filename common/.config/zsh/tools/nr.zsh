nr() {
  local selected_command

  selected_command=$(command nr "$@") || return
  if [[ -z $selected_command ]]; then
    return 0
  fi

  print -z -- "$selected_command"
}
