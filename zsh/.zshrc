# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes

if [[ -n "$TMUX" ]]; then
else
  ZSH_THEME="powerlevel10k/powerlevel10k"
fi


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

source $ZSH/oh-my-zsh.sh

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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
if [[ -n "$TMUX" ]]; then
  eval "$(starship init zsh)"
else
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

PATH=~/.console-ninja/.bin:$PATH
eval $(thefuck --alias)

# place this after nvm initialization!
autoload -U add-zsh-hook

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

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"

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

source ~/fzf-git.sh/fzf-git.sh

export _ZO_DATA_DIR=$HOME/Library/Application Support

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

# fzf git branch search
gs() {
  case "$*" in
    *--fetch*) git fetch --prune ;;
  esac

  local source="remote"
  case "$*" in
    *--local*) source="local" ;;
  esac

  local query=""
  for arg in "$@"; do
    case "$arg" in
      --*) ;; # skip flags
      *) query="$arg" ;;
    esac
  done

  local branch_list=""
  local preview_cmd=""
  if [ "$source" = "local" ]; then
    branch_list=$(git for-each-ref --format='%(refname:short)' refs/heads)
    preview_cmd='git log -5 --color=always --format="%C(bold yellow)%h%Creset %s%n%C(dim cyan)%an%Creset, %C(blue)%cr%Creset" {}'
  else
    branch_list=$(
      git for-each-ref --format='%(refname:short)' refs/remotes/origin \
        | grep -v '^origin/HEAD$' \
        | sed 's|^origin/||'
    )
    preview_cmd='git log -5 --color=always --format="%C(bold yellow)%h%Creset %s%n%C(dim cyan)%an%Creset, %C(blue)%cr%Creset" origin/{}'
  fi

  if [ -n "$query" ]; then
    local match
    match=$(printf "%s\n" "$branch_list" | grep -i -F -x "$query" | head -n 1)
    if [ -z "$match" ]; then
      match=$(printf "%s\n" "$branch_list" | grep -i -F "$query" | head -n 1)
    fi

    if [ -n "$match" ]; then
      echo "🔁 Automatisch wechseln zu: $match"
      git switch "$match" \
        || git switch -c "$match" --track "origin/$match" \
        || echo "❌ Konnte nicht zu '$match' wechseln."
      return
    fi
  fi

  local branch
  branch=$(printf "%s\n" "$branch_list" | fzf \
    --prompt="🌀 Branch wählen [$source]: " \
    --preview="$preview_cmd" \
    --preview-window=down:20%:wrap)

  if [ -n "$branch" ]; then
    git switch "$branch" \
      || git switch -c "$branch" --track "origin/$branch" \
      || echo "❌ Konnte nicht zu '$branch' wechseln."
  else
    echo "🚫 Kein Branch ausgewählt."
  fi
}

gcmt() {
  emulate -L zsh -o pipefail

  # ANSI Farben
  local reset=$'\033[0m'
  local blue=$'\033[34m'
  local green=$'\033[32m'
  local yellow=$'\033[33m'
  local red=$'\033[31m'
  local gray=$'\033[90m'

  local msg
  if (( $# == 0 )); then
    printf "${yellow}Message:${reset} "
    IFS= read -r msg
  else
    msg="$*"
  fi

  local branch ticket project number
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || branch=''

  if [[ $branch =~ '^[^/]+/([A-Za-z][A-Za-z0-9]+)-([0-9]+)' ]]; then
    project=${match[1]}
    number=${match[2]}
    ticket="${project:u}-${number}"
  else
    ticket=""
  fi

  local final_msg
  if [[ -n $ticket ]]; then
    local lower_msg="${(L)msg}"
    local lower_ticket="${(L)ticket}"
    if [[ $lower_msg == ${lower_ticket}:* || $lower_msg == ${lower_ticket}\ * ]]; then
      final_msg="$msg"
    else
      final_msg="$ticket: $msg"
    fi
  else
    final_msg="$msg"
  fi

  echo "Commit-Message: \"${yellow}${final_msg}${reset}\""
  printf "${yellow}Approve?${reset} (y/${green}ENTER${reset} = yes, ${red}n${reset}/ESC = no) "

  local key
  read -rs -k 1 key
  echo
  if [[ $key == $'\e' || $key == 'n' || $key == 'N' ]]; then
    echo "${red}❌ Abgebrochen.${reset}"
    return 1
  fi
  if [[ -n $key && $key != $'\n' && $key != 'y' && $key != 'Y' ]]; then
    echo "${red}❌ Abgebrochen.${reset}"
    return 1
  fi

  echo "${green}✅ Committing...${reset}"
  git commit -m "$final_msg"
}

alias dotfiles='/usr/bin/git --git-dir=$HOME/dotfiles/.git --work-tree=$HOME/dotfiles'
export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"
export JAVA_HOME="/opt/homebrew/Cellar/openjdk@11/11.0.25/libexec/openjdk.jdk/Contents/Home"

alias nv='neovide'

export PATH=$PATH:$HOME/go/bin
