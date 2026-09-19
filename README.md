# Venom  
## Python Virtual Environment Manager  
### A global venv for your entire system

Venom is a lightweight shell script that creates and manages a **single global Python virtual environment** shared across your operating system. It automatically provisions the environment on first run, fixes permissions, and launches a shell with a custom prompt that clearly indicates the active Venom environment.

<img width="315" height="465" alt="Screenshot of the Venom script running in a terminal" src="https://github.com/user-attachments/assets/5731def5-6d2f-4278-a16d-6f10f73f99ee" />

---

## Features

- **Global environment:** Uses one shared virtual environment at `/usr/local/venv/default`.
- **Automatic bootstrap:** Creates the directory and initializes the venv during the first run.
- **Proper permissions:** Recursively sets ownership so `pip` works without `sudo`.
- **Custom prompt:** Starts a new Bash session with a styled Venom prompt.
- **Single command:** After installation, run it using the `venom` command.

---

## Installation

```bash
git clone https://github.com/Szmelc-INC/Venom.git
cd Venom
sudo install -m 755 venv.sh /bin/venom
```

---

## Usage

Start or enter the Venom environment:

```bash
venom
```

On the first invocation, Venom will:

- Ask for `sudo` to create `/usr/local/venv`
- Initialize the `default` environment  
- Fix directory ownership

Subsequent runs will **not** require `sudo`.

When activated, Venom opens a new Bash session with a prompt like:

```
[V] [default] user@host ~ $
```

To exit the virtual environment:

```bash
exit
```

---

## How It Works

The script performs the following steps:

1. **Environment check**  
   Looks for `/usr/local/venv/default`.  
   If missing, Venom runs a one-time setup:
   - Creates `/usr/local/venv`
   - Initializes `python -m venv /usr/local/venv/default`

2. **Ownership fix**  
   Runs `sudo chown -R $USER:$USER /usr/local/venv`  
   This ensures pip installs work normally.

3. **Integrity check**  
   Confirms that `activate` exists.

4. **Activation**  
   Launches a fresh Bash instance using:
   ```
   exec bash --rcfile <( … )
   ```
   This session:
   - Sources the venv `activate` script  
   - Applies Venom’s custom PS1 prompt

