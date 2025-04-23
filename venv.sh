#!/bin/bash
# [Venom] - [v1] 
# Venv Helper by Szmelc.INC 

venv_dir="/usr/local/venv"
default_env="$venv_dir/default"

# Setup stage
if [ ! -d "$default_env" ]; then
    echo "[+] Setting up venv environment (sudo required)"
    sudo mkdir -p "$venv_dir"
    sudo python -m venv "$default_env"
fi

# Fix ownership
sudo chown -R "$USER:$USER" "$venv_dir"

# Confirm valid venv
if [ ! -f "$default_env/bin/activate" ]; then
    echo "[-] Missing activate script. Venv may be broken."
    exit 1
fi

# Activate with sexy garbage prompt
echo "[+] Activating default venv..."
exec bash --rcfile <(cat <<EOF
export VIRTUAL_ENV_DISABLE_PROMPT=1
source "$default_env/bin/activate"
# Custom PS1 with cursed colors
PS1="[\\[\\e[1;91m\\]V\\[\\e[0m\\]] [\\[\\e[1;93m\\]default\\[\\e[0m\\]] \\[\\e[1;96m\\]\\u@\\h\\[\\e[0m\\] \\[\\e[1;95m\\]\\w\\[\\e[0m\\] \$ "
EOF
)
