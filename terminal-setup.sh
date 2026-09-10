#!/bin/bash

# My idempotent setup for new environments
# Inspired by:
# https://raw.githubusercontent.com/markcallen/dotfiles/master/terminal-setup.sh
#
# Usage (preferred - buffers the whole script before running it):
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/cmatthewbrooks/dotfiles/main/terminal-setup.sh)"
#
#######################################
# PORTABILITY CONSTRAINT
#
# macOS ships bash 3.2.57 (frozen at the last GPLv2 release) and this script
# runs BEFORE Homebrew exists, so it executes under 3.2. That rules out:
#   - associative arrays (declare -A)
#   - ${var,,} / ${var^^} case conversion
#   - mapfile / readarray
#   - the &>> redirect
# Also note: under `set -u`, expanding "${arr[@]}" on an EMPTY array is a fatal
# "unbound variable" error in 3.2 (fixed in 4.4). Use ${arr[@]+"${arr[@]}"}.
#######################################

set -Eeuo pipefail

# Everything lives inside main() so that a truncated `curl | bash` download
# fails to parse rather than executing half a provisioning run.
main() {

  START_TS="$(date +%s)"

  DRY_RUN=0
  WITH_CASKS=0
  SKIP_STEPS=""
  WARNINGS=0
  SUMMARY=""
  NEXT_STEPS=""

  #######################################
  # Usage

  usage() {
    cat <<'EOF'
Usage: terminal-setup.sh [OPTIONS]

Idempotent environment bootstrap for new macOS and Linux hosts.

Options:
  -n, --dry-run     Print what would be done without making changes
      --casks       Also install macOS GUI apps from brew/Brewfile.macos
      --skip STEP   Skip a step; repeatable. One of:
                    ssh, brew, shell, omz, dirs, dotfiles, claude
      --no-color    Disable ANSI color output (also honors NO_COLOR)
  -h, --help        Show this help and exit
EOF
  }

  #######################################
  # Arg parsing

  USE_COLOR=1

  while [ $# -gt 0 ]; do
    case "$1" in
      -n|--dry-run) DRY_RUN=1 ;;
      --casks)      WITH_CASKS=1 ;;
      --skip)
        [ $# -ge 2 ] || { echo "--skip requires a step name" >&2; exit 1; }
        SKIP_STEPS="$SKIP_STEPS $2"
        shift
        ;;
      --no-color)   USE_COLOR=0 ;;
      -h|--help)    usage; exit 0 ;;
      *)
        echo "Unknown argument: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done

  #######################################
  # Output helpers
  #
  # Colors are disabled when stdout is not a TTY so piped output and logs stay
  # clean, and when NO_COLOR is set (emerging convention).

  if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "$USE_COLOR" -eq 1 ]; then
    C_RESET=$'\033[0m'
    C_BLUE=$'\033[34m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_RED=$'\033[31m'
    C_DIM=$'\033[2m'
  else
    C_RESET=""; C_BLUE=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_DIM=""
  fi

  ts()   { date +%Y-%m-%dT%H:%M:%S%z; }
  step() { printf '%s==>%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
  info() { printf '  - %s\n' "$*"; }
  ok()   { printf '  %s+%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
  warn() { printf '  %s!%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; WARNINGS=$((WARNINGS + 1)); }
  die()  { printf '  %sx%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

  # Record a line for the end-of-run summary: record <ok|skip|warn> <message>
  record() { SUMMARY="${SUMMARY}${1}|${2}
"; }

  # Queue a manual follow-up to print at the very end, where it won't scroll
  # past under minutes of Homebrew output.
  add_next_step() { NEXT_STEPS="${NEXT_STEPS}  * ${1}
"; }

  # Run (or log) a mutating command. Takes an argv array and execs it directly,
  # so there is NO shell involved: pipes, redirects and && do not work here.
  # Use run_sh for those. Never mix the two.
  run() {
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "[DRY-RUN] would run: $*"
    else
      "$@"
    fi
  }

  # Run (or log) a command that genuinely needs shell syntax.
  run_sh() {
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "[DRY-RUN] would run (sh): $*"
    else
      sh -c "$*"
    fi
  }

  # Should this step run? Used by the --skip flag.
  should_run() {
    case " $SKIP_STEPS " in
      *" $1 "*)
        info "skipping $1 (--skip)"
        record skip "$1 (skipped via --skip)"
        return 1
        ;;
    esac
    return 0
  }

  #######################################
  # Summary report
  #
  # Wired to EXIT so the summary prints even when set -e aborts the run, which
  # is exactly when you most want to know how far it got.

  print_summary() {
    # $? must be captured on the first line, before anything overwrites it.
    summary_rc=$?

    printf '\n%s========================================%s\n' "$C_BLUE" "$C_RESET"
    printf '%s Setup summary %s%s\n' "$C_BLUE" "$(ts)" "$C_RESET"
    printf '%s========================================%s\n' "$C_BLUE" "$C_RESET"

    printf '%s' "$SUMMARY" | while IFS='|' read -r status msg; do
      [ -n "$status" ] || continue
      case "$status" in
        ok)   printf '  %s+%s %s\n' "$C_GREEN"  "$C_RESET" "$msg" ;;
        skip) printf '  %s-%s %s\n' "$C_DIM"    "$C_RESET" "$msg" ;;
        warn) printf '  %s!%s %s\n' "$C_YELLOW" "$C_RESET" "$msg" ;;
        *)    printf '  %s\n' "$msg" ;;
      esac
    done

    printf '\n  Elapsed: %ss   Warnings: %s\n' "$(( $(date +%s) - START_TS ))" "$WARNINGS"

    if [ "$summary_rc" -ne 0 ]; then
      printf '  %sRun failed with status %s%s\n' "$C_RED" "$summary_rc" "$C_RESET"
    fi

    if [ -n "$NEXT_STEPS" ]; then
      printf '\n%s Manual next steps %s\n' "$C_BLUE" "$C_RESET"
      printf '%s' "$NEXT_STEPS"
    fi

    return $summary_rc
  }

  on_error() {
    printf '  %sx%s failed at line %s\n' "$C_RED" "$C_RESET" "$1" >&2
  }

  trap 'on_error $LINENO' ERR
  trap print_summary EXIT

  if [ "$DRY_RUN" -eq 1 ]; then
    step "Running in --dry-run mode: no changes will be made"
    info "NOTE: dry-run reports the first action of each step. Later steps may"
    info "      differ, since they branch on state earlier steps would create."
  fi

  #######################################
  # Host OS detection

  OS="$(uname -s)"
  case "$OS" in
    Darwin) IS_MACOS=1 ;;
    Linux)  IS_MACOS=0 ;;
    *) die "Unsupported OS: $OS" ;;
  esac

  step "Detected OS: $OS"

  #######################################
  # Preconditions
  #
  # Fail in second one rather than minute six: git is not needed until the very
  # last step, but is genuinely absent on minimal VPS images.

  step "Checking prerequisites"

  for required in curl uname; do
    command -v "$required" >/dev/null 2>&1 || die "required command not found: $required"
  done
  ok "curl and uname present"

  if ! command -v git >/dev/null 2>&1; then
    info "git not found, installing"
    if [ "$IS_MACOS" -eq 1 ]; then
      # On macOS git arrives with the Xcode Command Line Tools.
      die "git not found. Install the Xcode Command Line Tools first: xcode-select --install"
    elif command -v apt-get >/dev/null 2>&1; then
      run sudo apt-get update -qq
      run sudo apt-get install -y git
    else
      die "git not found and no supported package manager available to install it"
    fi
  fi
  ok "git present"

  # Homebrew cannot install or build anything without the CLT. Detect and exit
  # rather than blocking on a GUI dialog; this script is idempotent, so
  # re-running once the installer finishes is cheap.
  if [ "$IS_MACOS" -eq 1 ] && ! xcode-select -p >/dev/null 2>&1; then
    warn "Xcode Command Line Tools missing"
    info "Run: xcode-select --install"
    info "Then re-run this script once it finishes."
    die "Xcode Command Line Tools are required before Homebrew can be installed"
  fi

  record ok "prerequisites checked"

  #######################################
  # SSH key setup
  #
  # DISABLED: the overall SSH flow is being reworked around 1Password (agent +
  # key storage), which changes where keys live and whether this script should
  # generate them at all. Kept here for reference until that lands.
  #
  # Note when re-enabling: these keys have no matching ~/.ssh/config, so nothing
  # actually uses them yet. The `ssh` value for --skip is still accepted.
  #
  # if should_run ssh; then
  #   step "Checking SSH keys"
  #
  #   run mkdir -p "$HOME/.ssh"
  #   run chmod 700 "$HOME/.ssh"
  #
  #   if [ "$IS_MACOS" -eq 1 ]; then
  #     SSH_KEY_NAMES=(personal github digitalocean)
  #   else
  #     SSH_KEY_NAMES=(default)
  #   fi
  #
  #   generated_keys=0
  #
  #   for key_name in ${SSH_KEY_NAMES[@]+"${SSH_KEY_NAMES[@]}"}; do
  #     key_path="$HOME/.ssh/id_ed25519_${key_name}"
  #     if [ -f "$key_path" ]; then
  #       info "$key_name: found ($key_path)"
  #     else
  #       info "$key_name: missing, generating"
  #       # -q keeps ssh-keygen from prompting; the -f guard above already
  #       # ensures we never overwrite an existing key.
  #       run ssh-keygen -q -t ed25519 -f "$key_path" -N "" \
  #         -C "${key_name}@$(uname -n | cut -d. -f1)-$(date +%Y%m%d)"
  #       run chmod 600 "$key_path"
  #       generated_keys=$((generated_keys + 1))
  #
  #       # ssh-add is fatal under set -e when no agent is running, which is the
  #       # common case on a fresh VPS. Never let it abort the run.
  #       if [ -n "${SSH_AUTH_SOCK:-}" ]; then
  #         if [ "$IS_MACOS" -eq 1 ]; then
  #           run ssh-add --apple-use-keychain "$key_path" || warn "ssh-add failed for $key_name"
  #         else
  #           run ssh-add "$key_path" || warn "ssh-add failed for $key_name"
  #         fi
  #       else
  #         info "  no ssh-agent running, skipping ssh-add"
  #       fi
  #
  #       add_next_step "Register public key: ${key_path}.pub"
  #     fi
  #   done
  #
  #   if [ "$generated_keys" -gt 0 ]; then
  #     record ok "generated $generated_keys SSH key(s)"
  #   else
  #     record ok "SSH keys already present"
  #   fi
  # fi

  record skip "SSH key setup (disabled pending 1Password rework)"

  #######################################
  # Directory structure setup

  if should_run dirs; then
    step "Checking preferred directory structure"

    DIRS=("$HOME/src" "$HOME/.local/bin")

    for dir in ${DIRS[@]+"${DIRS[@]}"}; do
      if [ -d "$dir" ]; then
        info "$dir already exists"
      else
        info "$dir missing, creating"
        run mkdir -p "$dir"
      fi
    done

    record ok "directory structure ready"
  fi

  #######################################
  # Dotfiles repo setup
  #
  # This runs BEFORE the Homebrew package step because the Brewfile lives in
  # this repo and is the single source of truth for packages.

  DOTFILES_REPO_HTTPS="https://github.com/cmatthewbrooks/dotfiles.git"
  DOTFILES_REPO_SSH="git@github.com:cmatthewbrooks/dotfiles.git"
  DOTFILES_DIR="$HOME/src/dotfiles"

  if should_run dotfiles; then
    step "Checking dotfiles repo"

    if [ -d "$DOTFILES_DIR/.git" ]; then
      info "$DOTFILES_DIR already exists, pulling latest"
      # --ff-only so a dirty or diverged checkout warns instead of dropping
      # into an interactive merge and aborting the run under set -e.
      run git -C "$DOTFILES_DIR" pull --ff-only \
        || warn "git pull failed (local changes?), continuing with existing checkout"
    else
      # Clone over HTTPS: the SSH key was likely only just generated and is not
      # registered with GitHub yet.
      info "$DOTFILES_DIR missing, cloning"
      run git clone "$DOTFILES_REPO_HTTPS" "$DOTFILES_DIR"
    fi

    # Prefer the SSH remote once the key actually authenticates.
    if [ "$DRY_RUN" -eq 0 ] && [ -d "$DOTFILES_DIR/.git" ]; then
      if ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 \
           | grep -q 'successfully authenticated'; then
        run git -C "$DOTFILES_DIR" remote set-url origin "$DOTFILES_REPO_SSH"
        info "remote set to SSH"
      else
        info "GitHub SSH auth not available yet, keeping HTTPS remote"
      fi
    fi

    record ok "dotfiles repo ready"
  fi

  #######################################
  # Homebrew setup

  if should_run brew; then
    step "Checking Homebrew"

    # Quieter, faster, and non-blocking. NONINTERACTIVE also stops the official
    # installer waiting on "Press RETURN", which cannot be answered when stdin
    # is the script itself under `curl | bash`.
    export NONINTERACTIVE=1
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_NO_ENV_HINTS=1
    export HOMEBREW_NO_INSTALL_CLEANUP=1

    if command -v brew >/dev/null 2>&1; then
      info "Homebrew already installed"
    else
      info "Homebrew not found, installing"
      # Single quotes keep $(curl ...) unexpanded until run() decides to
      # execute it. Double quotes here would download the installer even in
      # --dry-run and print its entire body as the "would run" message.
      run /bin/bash -c 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    fi

    # Homebrew's prefix is not on the default PATH (/opt/homebrew on Apple
    # Silicon, /home/linuxbrew/.linuxbrew on Linux), so a freshly installed
    # brew is unreachable by the very next command without this.
    if ! command -v brew >/dev/null 2>&1; then
      for brew_bin in /opt/homebrew/bin/brew \
                      /usr/local/bin/brew \
                      /home/linuxbrew/.linuxbrew/bin/brew \
                      "$HOME/.linuxbrew/bin/brew"; do
        if [ -x "$brew_bin" ]; then
          eval "$("$brew_bin" shellenv)"
          info "loaded brew environment from $brew_bin"
          break
        fi
      done
    fi

    if command -v brew >/dev/null 2>&1; then
      # One explicit update per run, then suppress the per-invocation
      # auto-update so a multi-package install doesn't re-check repeatedly.
      run brew update --quiet || warn "brew update failed, continuing"
      export HOMEBREW_NO_AUTO_UPDATE=1

      BREWFILE="$DOTFILES_DIR/brew/Brewfile"

      if [ -f "$BREWFILE" ]; then
        # --no-lock keeps brew from writing Brewfile.lock.json into the repo,
        # which would dirty the tree and break the next run's --ff-only pull.
        # --no-upgrade keeps re-runs fast and idempotent in spirit.
        if brew bundle check --file="$BREWFILE" >/dev/null 2>&1; then
          info "all formulae from Brewfile already installed"
          record ok "Homebrew formulae already present"
        else
          info "installing formulae from $BREWFILE"
          run brew bundle install --file="$BREWFILE" --no-upgrade --no-lock
          record ok "Homebrew formulae installed"
        fi

        CASKFILE="$DOTFILES_DIR/brew/Brewfile.macos"
        if [ "$IS_MACOS" -eq 1 ] && [ "$WITH_CASKS" -eq 1 ] && [ -f "$CASKFILE" ]; then
          info "installing macOS casks from $CASKFILE"
          run brew bundle install --file="$CASKFILE" --no-upgrade --no-lock
          record ok "macOS casks installed"
        elif [ "$IS_MACOS" -eq 1 ] && [ "$WITH_CASKS" -eq 0 ]; then
          info "skipping GUI casks (pass --casks to install them)"
          record skip "macOS casks (use --casks)"
        fi
      else
        warn "Brewfile not found at $BREWFILE, falling back to built-in list"
        # Standalone fallback for a run where the repo isn't available.
        BREW_PACKAGES=(vim tmux uv jq tree gron colordiff ascii)
        run brew install ${BREW_PACKAGES[@]+"${BREW_PACKAGES[@]}"}
        record warn "installed fallback package list (no Brewfile)"
      fi
    else
      warn "brew unavailable after install attempt, skipping packages"
      record warn "Homebrew unavailable"
    fi
  fi

  #######################################
  # Claude Code setup
  #
  # The official installer drops a native binary in ~/.local/bin, which the
  # dirs step above has already created and the deployed zshrc puts on PATH.

  if should_run claude; then
    step "Checking Claude Code"

    if command -v claude >/dev/null 2>&1; then
      info "Claude Code already installed"
      record ok "Claude Code already present"
    elif [ -x "$HOME/.local/bin/claude" ]; then
      # Installed, but this shell's PATH predates it (fresh host, first run).
      info "Claude Code already installed (not yet on PATH)"
      record ok "Claude Code already present"
    else
      info "Claude Code not found, installing"
      # Download to a temp file first, the same way the oh-my-zsh step does:
      # piping curl into bash runs a partial script if the transfer dies.
      CLAUDE_INSTALLER="${TMPDIR:-/tmp}/claude-install.$$.sh"
      if [ "$DRY_RUN" -eq 1 ]; then
        echo "[DRY-RUN] would download and run the Claude Code installer"
        record skip "Claude Code (dry-run)"
      elif curl -fsSL -o "$CLAUDE_INSTALLER" https://claude.ai/install.sh \
           && bash "$CLAUDE_INSTALLER"; then
        rm -f "$CLAUDE_INSTALLER"
        record ok "Claude Code installed"
      else
        rm -f "$CLAUDE_INSTALLER"
        warn "Claude Code install failed, continuing"
        record warn "Claude Code not installed"
      fi
    fi
  fi

  #######################################
  # oh-my-zsh setup
  #
  # The zshrc deployed by install.sh sources $ZSH/oh-my-zsh.sh, so without this
  # a "successful" run leaves a shell that errors on every prompt.

  if should_run omz; then
    step "Checking oh-my-zsh"

    if [ -d "$HOME/.oh-my-zsh" ]; then
      info "oh-my-zsh already installed"
      record ok "oh-my-zsh already present"
    else
      info "oh-my-zsh not found, installing"
      # --unattended implies RUNZSH=no and CHSH=no: without it the installer
      # launches an interactive zsh at the end and never returns, hanging the
      # script. --keep-zshrc protects the .zshrc install.sh is about to place.
      OMZ_INSTALLER="${TMPDIR:-/tmp}/omz-install.$$.sh"
      if [ "$DRY_RUN" -eq 1 ]; then
        echo "[DRY-RUN] would download and run the oh-my-zsh installer (--unattended --keep-zshrc)"
      else
        curl -fsSL -o "$OMZ_INSTALLER" \
          https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
        sh "$OMZ_INSTALLER" --unattended --keep-zshrc
        rm -f "$OMZ_INSTALLER"
      fi
      record ok "oh-my-zsh installed"
    fi

    # The zshrc lists zsh-syntax-highlighting as an oh-my-zsh plugin, which
    # requires a checkout under $ZSH_CUSTOM/plugins - the Homebrew formula
    # alone does not satisfy the OMZ plugin loader.
    ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    plugin_dir="$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"
    if [ -d "$plugin_dir" ]; then
      info "plugin zsh-syntax-highlighting already present"
    else
      info "plugin zsh-syntax-highlighting missing, cloning"
      run git clone --depth=1 \
        https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugin_dir" \
        || warn "failed to clone zsh-syntax-highlighting"
    fi
  fi

  #######################################
  # Default shell setup

  if should_run shell; then
    step "Checking default shell"

    ZSH_PATH="$(command -v zsh || true)"

    if [ -z "$ZSH_PATH" ]; then
      info "zsh not found, installing"
      if [ "$IS_MACOS" -eq 1 ]; then
        run brew install zsh
      elif command -v apt-get >/dev/null 2>&1; then
        run sudo apt-get update -qq
        run sudo apt-get install -y zsh
      else
        warn "no supported package manager found to install zsh"
      fi
      ZSH_PATH="$(command -v zsh || true)"
    fi

    if [ -z "$ZSH_PATH" ]; then
      if [ "$DRY_RUN" -eq 1 ]; then
        info "zsh install skipped (--dry-run), cannot determine path yet"
        record skip "default shell (dry-run)"
      else
        warn "zsh installation failed, skipping default shell setup"
        record warn "default shell not changed"
      fi
    else
      # $SHELL is the inherited env var, not the authoritative login shell, so
      # comparing against it makes chsh re-run on every invocation. Read the
      # real value and fall back through progressively weaker sources.
      current_shell="$(dscl . -read "$HOME" UserShell 2>/dev/null | awk '{print $2}')"
      if [ -z "$current_shell" ]; then
        current_shell="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7)"
      fi
      [ -n "$current_shell" ] || current_shell="$SHELL"

      if [ "$current_shell" = "$ZSH_PATH" ]; then
        info "zsh is already the login shell"
        record ok "zsh already default shell"
      else
        info "Login shell is $current_shell, switching to $ZSH_PATH"
        if ! grep -qxF "$ZSH_PATH" /etc/shells 2>/dev/null; then
          info "Adding $ZSH_PATH to /etc/shells"
          # Pass the path as $1 rather than interpolating it into the string.
          run sudo sh -c 'printf "%s\n" "$1" >> /etc/shells' _ "$ZSH_PATH"
        fi
        if run chsh -s "$ZSH_PATH"; then
          record ok "default shell set to zsh"
          add_next_step "Open a new terminal (or run: exec zsh) to pick up the new shell"
        else
          warn "chsh failed; run manually: chsh -s $ZSH_PATH"
          record warn "chsh failed"
        fi
      fi
    fi
  fi

  #######################################
  # Dotfiles install

  if should_run dotfiles; then
    step "Running dotfiles install.sh"

    if [ -x "$DOTFILES_DIR/install.sh" ]; then
      # Forward --dry-run so the riskiest part (actually placing files in
      # $HOME) can be previewed too.
      if [ "$DRY_RUN" -eq 1 ]; then
        "$DOTFILES_DIR/install.sh" --dry-run
      else
        "$DOTFILES_DIR/install.sh"
      fi
      record ok "dotfiles installed"
    else
      warn "$DOTFILES_DIR/install.sh not found or not executable"
      record warn "dotfiles install skipped"
    fi
  fi

  step "Done"
}

main "$@"
