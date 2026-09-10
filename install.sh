#!/usr/bin/env bash

# Deploy dotfiles from this repo into $HOME.
#
# Files are SYMLINKED, not copied, so that editing ~/.zshrc edits the repo file
# and `git pull` updates every config instantly. Anything already in the way is
# moved into a timestamped backup directory first - nothing is destroyed.
#
# See the portability note in terminal-setup.sh: this must stay bash 3.2 clean.

set -Eeuo pipefail

DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=1 ;;
    -h|--help)
      cat <<'EOF'
Usage: install.sh [--dry-run]

Symlinks this repo's config files into $HOME, backing up anything it replaces
to ~/.dotfiles-backup/YYYYMMDD-HHMMSS/.
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
  shift
done

SCRIPTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

LINKED=0
ALREADY=0
BACKED_UP=0

echo "[+] Installing config files..."
[ "$DRY_RUN" -eq 1 ] && echo "[+] --dry-run: no changes will be made"

# Symlink one file into place, backing up whatever was there before.
link_file() {
  src="$1"
  dest="$2"

  if [ ! -e "$src" ]; then
    echo "  ! source missing, skipping: $src" >&2
    return 0
  fi

  # Already pointing where we want? Nothing to do. Compare the target rather
  # than just testing existence, so a stale symlink gets replaced.
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "  = $dest (already linked)"
    ALREADY=$((ALREADY + 1))
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    if [ -e "$dest" ] || [ -L "$dest" ]; then
      echo "  [DRY-RUN] would back up $dest and link -> $src"
    else
      echo "  [DRY-RUN] would link $dest -> $src"
    fi
    return 0
  fi

  # This mkdir is what makes ~/.config, ~/.pip and the oh-my-zsh themes
  # directory work on a fresh host.
  mkdir -p "$(dirname "$dest")"

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "${dest#"$HOME"/}")"
    mv "$dest" "$BACKUP_DIR/${dest#"$HOME"/}"
    echo "  ~ backed up existing $dest"
    BACKED_UP=$((BACKED_UP + 1))
  fi

  ln -s "$src" "$dest"
  echo "  + $dest -> $src"
  LINKED=$((LINKED + 1))
}

#######################################
# Deployment map: <repo path> <destination relative to $HOME>

# zsh uses a $ZDOTDIR layout: only .zshenv can live in $HOME (zsh always reads
# it from there), and it points at ~/.config/zsh for everything else.
MAPPINGS="
zsh/zshenv-bootstrap .zshenv
zsh/zshenv           .config/zsh/.zshenv
zsh/zprofile         .config/zsh/.zprofile
zsh/zshrc            .config/zsh/.zshrc
zsh/cmb.zsh-theme    .oh-my-zsh/custom/themes/cmb.zsh-theme
git/gitignore        .gitignore
vim/vimrc            .vimrc
tmux/tmux.conf       .tmux.conf
radare2/radare2rc    .radare2rc
radare2/cmbday.r2    .cmbday.r2
python/flake8        .config/flake8
python/pip.conf      .pip/pip.conf
lldb/lldbinit        .lldbinit
ida/idapythonrc.py   .idapro/idapythonrc.py
ida/ida_default.css  .idapro/themes/default/user.css
ida/ida_dark.css     .idapro/themes/dark/user.css
"

# A here-string rather than a pipe: `while read` in a pipeline runs in a
# subshell on bash 3.2, which would discard the counters above.
while read -r src dest; do
  [ -n "$src" ] || continue
  link_file "$SCRIPTPATH/$src" "$HOME/$dest"
done <<< "$MAPPINGS"

#######################################
# git config
#
# ~/.gitconfig is deliberately NOT a symlink: `git config --global` rewrites
# this file in place, which through a symlink would silently edit the repo.
# Instead the tracked config is linked alongside it and included by reference,
# which also leaves a safe home for machine-local settings.

echo "[+] Configuring git"
link_file "$SCRIPTPATH/git/gitconfig" "$HOME/.gitconfig-cmb"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "  [DRY-RUN] would ensure ~/.gitconfig includes ~/.gitconfig-cmb"
elif [ -f "$HOME/.gitconfig" ] && grep -q 'gitconfig-cmb' "$HOME/.gitconfig" 2>/dev/null; then
  echo "  = ~/.gitconfig already includes ~/.gitconfig-cmb"
else
  if [ -e "$HOME/.gitconfig" ] || [ -L "$HOME/.gitconfig" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$HOME/.gitconfig" "$BACKUP_DIR/.gitconfig"
    echo "  ~ backed up existing ~/.gitconfig"
    BACKED_UP=$((BACKED_UP + 1))
  fi
  printf '[include]\n\tpath = ~/.gitconfig-cmb\n' > "$HOME/.gitconfig"
  echo "  + ~/.gitconfig includes ~/.gitconfig-cmb"
fi

#######################################
# zsh rc.d fragments
#
# Linked individually rather than as one directory symlink so that a fragment
# deleted from the repo leaves a dangling link that is visibly broken, instead
# of silently vanishing from a shell that still works.

echo "[+] Installing zsh rc.d fragments"
if [ -d "$SCRIPTPATH/zsh/rc.d" ]; then
  for fragment in "$SCRIPTPATH"/zsh/rc.d/*.zsh; do
    [ -f "$fragment" ] || continue
    link_file "$fragment" "$HOME/.config/zsh/rc.d/$(basename "$fragment")"
  done
fi

#######################################

echo "[+] Installing config files...DONE"
echo "    linked: $LINKED   already correct: $ALREADY   backed up: $BACKED_UP"
if [ "$BACKED_UP" -gt 0 ]; then
  echo "    backups saved to: $BACKUP_DIR"
fi
