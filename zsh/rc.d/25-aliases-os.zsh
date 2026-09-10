# Platform-specific aliases. The BSD userland on macOS and the GNU userland on
# a Linux VPS disagree on flags here, so each side gets its own definition.

if [[ "$OSTYPE" == darwin* ]]; then
  alias ls="ls -1G"
  alias localip="ipconfig getifaddr en0"
else
  alias ls="ls -1 --color=auto"
  # No ipconfig on Linux; ask iproute2 which address serves the default route.
  alias localip="ip -4 -oneline addr show scope global | awk '{print \$4}' | cut -d/ -f1"
fi
