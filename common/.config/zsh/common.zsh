# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-z zsh-vi-mode)

if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

export EDITOR='nvim'

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

PATH=~/.console-ninja/.bin:$PATH
if command -v thefuck >/dev/null 2>&1; then
  eval "$(thefuck --alias)"
fi

# place this after nvm initialization!
autoload -U add-zsh-hook

if command -v nvm >/dev/null 2>&1; then
  load-nvmrc() {
    local nvmrc_path
    nvmrc_path="$(nvm_find_nvmrc)"

    if [ -n "$nvmrc_path" ]; then
      local nvmrc_node_version
      nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

      if [ "$nvmrc_node_version" = "N/A" ]; then
        nvm install
      elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
        nvm use
      fi
    elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
      echo "Reverting to nvm default version"
      nvm use default
    fi
  }

  add-zsh-hook chpwd load-nvmrc
  load-nvmrc
fi

# Set up fzf key bindings and fuzzy completion
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi

# -- Use fd instead of fzf --

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

if [[ -f "$HOME/fzf-git.sh/fzf-git.sh" ]]; then
  source "$HOME/fzf-git.sh/fzf-git.sh"
fi

export BAT_THEME=tokyonight_night

# ---- Eza (better ls) -----

unalias ls 2>/dev/null
ls() {
  if [[ "$1" == "-l" || "$1" == "-la" ]]; then
    eza --color=always --group-directories-first --long --icons=always --no-time "$@"
  else
    eza --color=always --group-directories-first --long --icons=always --no-time --no-user --no-permissions "$@"
  fi
}

# bat preview in fzf
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo $'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
  esac
}

function yy() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

alias dotfiles='/usr/bin/git --git-dir=$HOME/dotfiles/.git --work-tree=$HOME/dotfiles'

alias nv='neovide'
alias oc='opencode'

export PATH=$PATH:$HOME/go/bin

# import git scripts
if [[ -f "$HOME/.config/zsh/git/gs.zsh" ]]; then
  source "$HOME/.config/zsh/git/gs.zsh"
fi
if [[ -f "$HOME/.config/zsh/git/gc.zsh" ]]; then
  source "$HOME/.config/zsh/git/gc.zsh"
fi
if [[ -f "$HOME/.config/zsh/git/gmr.zsh" ]]; then
  source "$HOME/.config/zsh/git/gmr.zsh"
fi
if [[ -f "$HOME/.config/zsh/git/gmro.zsh" ]]; then
  source "$HOME/.config/zsh/git/gmro.zsh"
fi

# nach dem eval von Starship
if [[ -f "$HOME/.config/zsh/startship/transient_prompt.zsh" ]]; then
  source "$HOME/.config/zsh/startship/transient_prompt.zsh"
fi

# --- Dynamische Starship-Konfiguration nach Breite ---
# Schwelle (Spalten) frei anpassbar:
export STARSHIP_COLUMNS_THRESHOLD=${STARSHIP_COLUMNS_THRESHOLD:-100}

typeset -ga STARSHIP_PROFILES
STARSHIP_PROFILES=(catppuccin simple)
export STARSHIP_PROFILE=${STARSHIP_PROFILE:-catppuccin}

__starship_resolve_config() {
  local profile=$1
  local variant=$2
  local base="$HOME/.config/starship"
  local path=""

  if [[ $profile == catppuccin ]]; then
    if [[ $variant == min ]]; then
      path="$base/starship-min.toml"
    else
      path="$base/starship-full.toml"
    fi
  else
    path="$base/starship-${profile}-${variant}.toml"
  fi

  if [[ -f $path ]]; then
    print -r -- "$path"
    return 0
  fi

  if [[ $variant == min ]]; then
    local fallback=""
    if [[ $profile == catppuccin ]]; then
      fallback="$base/starship-full.toml"
    else
      fallback="$base/starship-${profile}-full.toml"
    fi
    if [[ -f $fallback ]]; then
      print -r -- "$fallback"
      return 0
    fi
  fi

  if [[ $profile != catppuccin ]]; then
    local catppuccin_fallback=""
    if [[ $variant == min ]]; then
      catppuccin_fallback="$base/starship-min.toml"
    else
      catppuccin_fallback="$base/starship-full.toml"
    fi
    if [[ -f $catppuccin_fallback ]]; then
      print -r -- "$catppuccin_fallback"
      return 0
    fi
  fi

  return 1
}

__starship_pick_config() {
  local variant="full"
  if (( COLUMNS < STARSHIP_COLUMNS_THRESHOLD )); then
    variant="min"
  fi

  local resolved
  resolved=$(__starship_resolve_config "${STARSHIP_PROFILE:-catppuccin}" "$variant") || return 0
  export STARSHIP_CONFIG="$resolved"
}

prompt() {
  local cmd=$1

  case "$cmd" in
    list)
      local current="${STARSHIP_PROFILE:-catppuccin}"
      local p
      for p in "${STARSHIP_PROFILES[@]}"; do
        if [[ $p == $current ]]; then
          print -r -- "$p <current>"
        else
          print -r -- "$p"
        fi
      done
      ;;
    set)
      local profile=$2
      if [[ -z $profile ]]; then
        print -r -- "usage: prompt set <profile>"
        return 1
      fi
      local found=0
      local p
      for p in "${STARSHIP_PROFILES[@]}"; do
        if [[ $p == $profile ]]; then
          found=1
          break
        fi
      done
      if (( ! found )); then
        print -r -- "unknown profile: $profile"
        return 1
      fi
      export STARSHIP_PROFILE="$profile"
      __starship_pick_config
      zle && zle reset-prompt
      ;;
    toggle)
      local current="${STARSHIP_PROFILE:-catppuccin}"
      local next=""
      local i
      for (( i = 1; i <= ${#STARSHIP_PROFILES[@]}; i++ )); do
        if [[ ${STARSHIP_PROFILES[i]} == $current ]]; then
          if (( i == ${#STARSHIP_PROFILES[@]} )); then
            next=${STARSHIP_PROFILES[1]}
          else
            next=${STARSHIP_PROFILES[i+1]}
          fi
          break
        fi
      done
      if [[ -z $next ]]; then
        next=${STARSHIP_PROFILES[1]}
      fi
      export STARSHIP_PROFILE="$next"
      __starship_pick_config
      zle && zle reset-prompt
      print -r -- "$next"
      ;;
    *)
      print -r -- "usage: prompt {list|set|toggle}"
      return 1
      ;;
  esac
}

# 1) Direkt einmal setzen (fuer den allerersten Prompt)
__starship_pick_config

# 2) Vor JEDEM Prompt erneut setzen (damit Resize sofort wirkt)
# sicherstellen, dass unser Hook VOR dem Prompt-Render laeuft:
precmd_functions=(__starship_pick_config "${precmd_functions[@]}")

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

export PATH="$HOME/.local/bin:$PATH"
