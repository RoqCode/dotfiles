# dotfiles

Single repo for shared and OS-specific configs using [GNU Stow](https://www.gnu.org/software/stow/).

## Packages

- `common`: shared configs (zsh, tmux, nvim, git, starship, etc.)
- `mac`: macOS-only configs (brew, yabai, skhd, iterm, keyboard layouts)
- `linux`: Omarchy/Linux-only configs (bashrc glue, system-specific bits)

## Installation

1. Install stow
   - macOS: `brew install stow`
   - Linux: `sudo pacman -S stow` or `sudo apt install stow`
2. Clone the repo
3. From the repo root:
   - macOS: `stow common mac`
   - Linux (Omarchy): `stow common linux`

> [!WARNING]
> Backup or remove any files that would be overwritten by symlinks.

## Omarchy note

Omarchy ships with bash by default. The `linux/.bashrc` in this repo execs `zsh -l` for interactive shells,
so your zsh config becomes the default experience.

## Adding a new configuration

1. Decide where it belongs: `common`, `mac`, or `linux`
2. Create the config file path inside that package
   - Example for tmux (shared): `common/.config/tmux/tmux.conf`
3. Apply with stow from repo root:

```sh
stow common
```

## Updating a configuration

Edits inside `dotfiles` apply immediately through the symlink. No need to re-run `stow` unless new files are added.

## Removing a configuration

```sh
stow -D common
```

## Tmux TPM

```sh
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```
