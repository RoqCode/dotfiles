case $- in
  *i*) ;;
  *) return ;;
esac

if command -v zsh >/dev/null 2>&1; then
  if [[ -z "${ZSH_VERSION:-}" ]]; then
    export SHELL="$(command -v zsh)"
    exec zsh -l
  fi
fi
