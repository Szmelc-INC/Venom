#!/bin/bash
# ==============================================================================
# [Venom] - [v2.1] - Python Venv Manager.
# ==============================================================================

set -e

# ==== CONFIG ====
VENV_DIR="/usr/local/venv"
DEFAULT_NAME="default"
DEFAULT_PY="python"

# ==== HELP ====
usage() {
    cat <<EOF
Usage: venom [flags]

Flags:
  -l             List all venvs
  -c <name>      Create new venv
  -r <name>      Delete venv (asks for confirmation)
  -u <name>      Activate venv (enter subshell)

Configuration options (use with -c):
  -p <version>    Select Python (e.g., "3.10", "3.12"). 
  Default: $DEFAULT_PY

Examples:
  venom -c 3-12 -p 3.12
  venom -u default
  venom
EOF
}

# ==== UTILS ====
confirm() {
    read -r -p "$1 [y/N]: " ans
    [[ "$ans" == "y" || "$ans" == "Y" ]]
}

ensure_base_dir() {
    if [ ! -d "$VENV_DIR" ]; then
        echo "[+] Tworzenie $VENV_DIR (wymaga sudo)..."
        sudo mkdir -p "$VENV_DIR"
        sudo chown -R "$USER:$USER" "$VENV_DIR"
    fi
}

list_venvs() {
    ensure_base_dir
    echo "[*] Dostępne venvy w $VENV_DIR:"
    find "$VENV_DIR" -maxdepth 1 -mindepth 1 -type d -printf "  - %f\n" | sort
}

create_venv() {
    local name="$1"
    local py_ver="$2"
    local path="$VENV_DIR/$name"

    ensure_base_dir

    if [ -d "$path" ]; then
        echo "[-] Venv '$name' już kurwa istnieje."
        exit 1
    fi

    # Parsowanie interpretera - wsparcie dla gołego "python" oraz dopisków typu "3.12"
    local py_exe="$py_ver"
    if ! command -v "$py_exe" &> /dev/null; then
        if command -v "python$py_exe" &> /dev/null; then
            py_exe="python$py_exe"
        else
            echo "[-] Błąd: Nie znaleziono interpretera '$py_ver' ani 'python$py_ver'."
            echo "[*] Zainstaluj go na Archu (np. yay -S python312)"
            exit 1
        fi
    fi

    echo "[+] Tworzenie venv '$name' przy użyciu: $py_exe"
    "$py_exe" -m venv "$path"
    echo "[+] Gotowe. Użyj: venom -u $name"
}

remove_venv() {
    local name="$1"
    local path="$VENV_DIR/$name"

    if [ ! -d "$path" ]; then
        echo "[-] Venv '$name' nie istnieje."
        exit 1
    fi

    if confirm "Na pewno chcesz rozjebać venv '$name'?"; then
        sudo rm -rf "$path"
        echo "[+] Usunięto '$name'."
    else
        echo "[*] Anulowano."
    fi
}

activate_venv() {
    local name="$1"
    local path="$VENV_DIR/$name"

    if [ ! -f "$path/bin/activate" ]; then
        echo "[-] '$name' nie jest prawidłowym venv."
        exit 1
    fi

    sudo chown -R "$USER:$USER" "$path" 2>/dev/null || true
    echo "[+] Wchodzę w środowisko: '$name'..."

    local current_shell=$(basename "$SHELL")

    if [[ "$current_shell" == "zsh" ]]; then
        # ZSH Hack: nadpisujemy ZDOTDIR, żeby poprawnie załadować konfigi
        TMP_ZDOTDIR=$(mktemp -d)
        cat <<EOF > "$TMP_ZDOTDIR/.zshrc"
if [ -f "\$HOME/.zshrc" ]; then
    source "\$HOME/.zshrc"
fi
export VIRTUAL_ENV_DISABLE_PROMPT=0
source "$path/bin/activate"
PROMPT="%F{red}[V]%f %F{yellow}[$name]%f \$PROMPT"
rm -rf "$TMP_ZDOTDIR"
EOF
        ZDOTDIR="$TMP_ZDOTDIR" exec zsh
    else
        exec bash --rcfile <(cat <<EOF
if [ -f "\$HOME/.bashrc" ]; then
    source "\$HOME/.bashrc"
fi
export VIRTUAL_ENV_DISABLE_PROMPT=0
source "$path/bin/activate"
PS1="\\[\\e[1;91m\\][V]\\[\\e[0m\\] \\[\\e[1;93m\\][$name]\\[\\e[0m\\] \$PS1"
EOF
)
    fi
}

# ==== ARG PARSING ====
ACTION=""
TARGET=""
TARGET_PY="$DEFAULT_PY"

OPTIND=1

while getopts ":lc:r:u:hp:" opt; do
    case "$opt" in
        l) ACTION="list" ;;
        c) ACTION="create"; TARGET="$OPTARG" ;;
        r) ACTION="remove"; TARGET="$OPTARG" ;;
        u) ACTION="use"; TARGET="$OPTARG" ;;
        p) TARGET_PY="$OPTARG" ;;
        h) usage; exit 0 ;;
        \?) echo "[-] Nieznana opcja: -$OPTARG"; usage; exit 1 ;;
        :) echo "[-] Opcja -$OPTARG wymaga argumentu."; exit 1 ;;
    esac
done

# ==== EXECUTION ====
case "$ACTION" in
    list)   list_venvs ;;
    create) create_venv "$TARGET" "$TARGET_PY" ;;
    remove) remove_venv "$TARGET" ;;
    use)    activate_venv "$TARGET" ;;
    *)
        ensure_base_dir
        if [ ! -d "$VENV_DIR/$DEFAULT_NAME" ]; then
            echo "[+] Ustawiam domyślny venv..."
            create_venv "$DEFAULT_NAME" "$DEFAULT_PY"
        fi
        activate_venv "$DEFAULT_NAME"
        ;;
esac
