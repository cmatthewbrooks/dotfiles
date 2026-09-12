# Third-party CLI tool integrations. Loaded after oh-my-zsh (10) because both
# of these emit completions and ZLE widgets that depend on compinit having
# already run.
#
# Each is guarded: these are brew-installed and may be absent on a fresh host
# or a minimal VPS, and an unguarded eval of a missing command would abort the
# rest of the fragment.

# fzf: Ctrl-R history search, Ctrl-T file picker, and ** completion.
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# zoxide: frecency-ranked cd replacement, exposed as `z`. Registers a chpwd
# hook to record directory visits.
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# tailscale: subcommand and flag completions. Not shipped as a static
# completion file by the brew formula, so it has to be generated per-shell.
if command -v tailscale >/dev/null 2>&1; then
  source <(tailscale completion zsh)
fi
