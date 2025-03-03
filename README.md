# dotfiles

My configuration dotfiles
This repository uses [GNU Stow](https://www.gnu.org/software/stow/) to manage dotfiles.  
Below are the steps to add a new configuration to this repository.

## Installation

1. Install homebrew
2. run `brew install stow`
3. run `git clone git@github.com:RoqCode/dotfiles.git`
   > [!WARNING]
   > backup or delete any folders/files that are tracked by this repository
4. run `cd dotfiles && stow <vim>`
   -- Replace `<vim>` with folder you want to symlink.

## 📌 Adding a new configuration

1. **Navigate to your dotfiles directory**

   ```sh
   cd ~/dotfiles
   ```

2. **Create a new folder for the configuration**  
   Each configuration should have its own directory, named after the application.  
   Example: For `tmux`, create:

   ```sh
   mkdir -p tmux/.config/tmux
   ```

3. **Move or create the configuration file**  
   Place the config files inside the corresponding directory.  
   Example: If `tmux` expects its config in `~/.config/tmux/tmux.conf`, do:

   ```sh
   mv ~/.config/tmux/tmux.conf tmux/.config/tmux/tmux.conf
   ```

4. **Apply the symlink with `stow`**  
   Run the following command from the `dotfiles` root:

   ```sh
   stow tmux
   ```

   This will create a symlink at `~/.config/tmux/tmux.conf` pointing to `~/dotfiles/tmux/.config/tmux/tmux.conf`.

5. **Verify the symlink**  
   Use `ls -l` to confirm:
   ```sh
   ls -l ~/.config/tmux/tmux.conf
   ```

## 🚀 Updating a Configuration

If you modify a config file inside `dotfiles`, the changes will be applied immediately to the real path due to the symlink. No need to re-run `stow` unless you've added a **new** config file.

## 🔄 Removing a Configuration

To remove a symlink but keep the original files:

```sh
stow -D tmux
```

## Reinstall tmux tmux

```
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```

```

```
