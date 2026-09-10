# dotfiles

This repository contains my terminal setup script and environment dotfiles.

## Git Workflow
- Use new branches for code changes.
- Use Conventional Commits: https://www.conventionalcommits.org/en/v1.0.0/#specification

## Structure
```
├── brew                        # Brewfiles
├── git                         # Configuration files for git
├── ida                         # Themes and configurations for IDA Pro Disassembler
├── lldb                        # Configurations for LLDB debugger
├── macos                       # Setup scripts for new macOS hosts
├── python                      # Configurations for Python3 development
├── radare2                     # Configurations for radare2 reverse engineering framework
├── tmux                        # Configurations for tmux
├── vim                         # Configurations for vim
├── zsh                         # Configurations for Z Shell
├── install.sh                  # Script to install dotfiles; invoked from terminal-setup.sh
├── terminal-setup.sh           # Main entrypoint for new environment setup
├── CLAUDE.md                   # Onboarding for Claude
└── README.md                   # Onboarding for Humans
```

### terminal-setup.sh
- Use native bash commands with no dependencies as this will be the first script
  run in new environments via `curl`
- This script should run on macOS for new hosts as well as Linux for VPS usage
- This script MUST stay idempotent
- Use helpful `echo` statements to show setup/installation progress
- Use comment banners in the source code to clearly separate sections
