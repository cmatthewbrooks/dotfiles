#!/bin/bash

# Globally-available Python CLI utilities. Each gets its own isolated venv via
# pipx, so these never collide with project dependencies or each other.

packages=(
    "black"
    "flake8"
    "rich-cli"
    "tldr"
    "yt-dlp"
)

echo "[+] Installing/Updating pipx packages"
for package in "${packages[@]}"; do
    echo "[+] Installing $package"
    pipx install --force "$package"
    echo "[+] Installing $package...DONE"
done
echo "[+] Installing/Updating pipx packages...DONE"
