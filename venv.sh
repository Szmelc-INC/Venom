#!/bin/bash
# [Venom] - [v1.2]
# Venv Helper by Szmelc.INC
# Minimal flags

set -e

# ==== CONFIG ====
venv_dir="/usr/local/venv"
default_name="default"

# ==== HELP ====
usage() {
    cat <<EOF
Usage: venom [options]

Options:
  -l              List all venvs
  -c <name>       Create venv
  -r <name>       Remove venv (asks before deleting)
  -u <name>       Use / activate venv
  -h              Show this help

No flags = activate default venv
EOF
}

# ==== UTILS ====
confirm() {
    read -r -p "$1 [y/N]: " ans
    [[ "$ans" == "y" || "$ans" == "Y" ]]
}

ensure_base_dir() {
    if [ ! -d "$venv_dir" ]; then
        echo "[+] Creating $venv_dir (sudo required)"
        sudo mkdir -p "$venv_dir"
        sudo chown -R "$USER:$USER" "$venv_dir"
    fi
}

list_venvs() {
    ensure_base_dir
    echo "[*] Available venvs:"
    find "$venv_dir" -maxdepth 1 -mindepth 1 -type d -printf "  - %f\n" | sort
}

create_venv() {
    local name="$1"
    local path="$venv_dir/$name"

    ensure_base_dir

    if [ -d "$path" ]; then
        echo "[-] Venv '$name' already exists"
        exit 1
    fi

    echo "[+] Creating venv '$name'"
    python -m venv "$path"
}

remove_venv() {
    local name="$1"
    local path="$venv_dir/$name"

    if [ ! -d "$path" ]; then
        echo "[-] Venv '$name' does not exist"
        exit 1
    fi

    if confirm "Are you sure you want to DELETE venv '$name'?"; then
        sudo rm -rf "$path"
        echo "[+] Removed '$name'"
    else
        echo "[*] Aborted"
    fi
}

activate_venv() {
    local name="$1"
    local path="$venv_dir/$name"

    if [ ! -f "$path/bin/activate" ]; then
        echo "[-] '$name' is not a valid venv"
        exit 1
    fi

    sudo chown -R "$USER:$USER" "$path"

    echo "[+] Activating '$name'..."
    exec bash --rcfile <(cat <<EOF
export VIRTUAL_ENV_DISABLE_PROMPT=0
source "$path/bin/activate"
PS1="[\\[\\e[1;91m\\]V\\[\\e[0m\\]] [\\[\\e[1;93m\\]$name\\[\\e[0m\\]] \\[\\e[1;96m\\]\\u@\\h\\[\\e[0m\\] \\[\\e[1;95m\\]\\w\\[\\e[0m\\] \$ "
EOF
)
}

# ==== ARG PARSING ====
while getopts ":lc:r:u:h" opt; do
    case "$opt" in
        l) list_venvs; exit 0 ;;
        c) create_venv "$OPTARG"; exit 0 ;;
        r) remove_venv "$OPTARG"; exit 0 ;;
        u) activate_venv "$OPTARG"; exit 0 ;;
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done

# ==== DEFAULT BEHAVIOR ====
ensure_base_dir

if [ ! -d "$venv_dir/$default_name" ]; then
    echo "[+] Setting up default venv (sudo required)"
    python -m venv "$venv_dir/$default_name"
fi

activate_venv "$default_name"
