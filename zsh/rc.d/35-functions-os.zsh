# Functions that depend on macOS-only tools (pbcopy, pkgutil). Guarded so a
# Linux VPS does not inherit commands that fail on first use.

if [[ "$OSTYPE" == darwin* ]]; then
  # Copy a file's SHA-256 to the clipboard, without a trailing newline.
  function getsha() {
      shasum -a 256 "$1" | cut -f 1 -d " " | tr -d '\n' | pbcopy
  }

  # Fully expand an installer .pkg into ./pkg_expanded for inspection.
  function pkgexpand() {
      pkgutil --expand-full "$1" pkg_expanded
  }
fi
