if [[ -f "$HOME/.config/zsh/common.zsh" ]]; then
  source "$HOME/.config/zsh/common.zsh"
fi

if [[ -f "$HOME/.config/zsh/os-detect.zsh" ]]; then
  source "$HOME/.config/zsh/os-detect.zsh"
fi

if [[ -n "$DOT_OS" && -f "$HOME/.config/zsh/os/${DOT_OS}.zsh" ]]; then
  source "$HOME/.config/zsh/os/${DOT_OS}.zsh"
fi

# bun completions
[ -s "/Users/hajo.haas/.bun/_bun" ] && source "/Users/hajo.haas/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

if command -v nvm >/dev/null 2>&1; then
  nvm use default >/dev/null 2>&1
  if (( ${+functions[load-nvmrc]} )); then
    load-nvmrc >/dev/null 2>&1
  fi
fi
