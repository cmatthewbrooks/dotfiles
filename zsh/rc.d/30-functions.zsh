# Portable shell functions.

# cd into a directory and immediately list it.
function cl() {
    cd "$@" && ls
}

# Create a directory (including parents) and cd into it.
function mkdircd() {
    mkdir -p "$1" && cd "$1"
}
alias newdir=mkdircd

# Print $PATH one entry per line.
function pathlines() {
    print -l $path
}

# Recursively checksum every file under a directory.
function shafind() {
    find "$1" -type f -exec shasum -a 256 {} ';'
}
