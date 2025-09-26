#!/bin/bash

#---------# VARIABLES #---------#

# PACKAGE INFO
INSTALL_DIR="$HOME/.local/bin"
INSTALL_NAME="ehu-tools"

# GITHUB
GITHUB_BASE_URL="https://raw.githubusercontent.com/KingJorjai/ehu-tools/refs/heads/"
GITHUB_EHUTOOLS_URL="$GITHUB_BASE_URL/main/ehu-tools.sh"

#---------# EHUTOOLS FUNCTIONS #---------#

install_ehutools() {
    # Ensure the installation directory exists
    mkdir -p "$INSTALL_DIR"

    # Download the script
    echo "[📥] Downloading $INSTALL_NAME..."
    divider
    curl -L "$GITHUB_EHUTOOLS_URL" -o "$INSTALL_DIR/$INSTALL_NAME"
    divider

    # Make it executable
    chmod +x "$INSTALL_DIR/$INSTALL_NAME"

    # Add to PATH if not already included
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$HOME/.bashrc"
        echo "[🔧] Added $INSTALL_DIR to PATH (restart your terminal or run 'source ~/.bashrc')"
    fi

    echo "[✅] Installation complete. You can now run '$INSTALL_NAME' from anywhere."
}

#---------# UTIL FUNCTIONS #---------#

save_user_screen() {
    printf '\e[?1049h'
}

restore_user_screen() {
    printf '\e[?1049l'
}

trap_ctrl_c() {
    restore_user_screen
    exit 1
}

press_any_key_to_continue() {
    read -rsn1 -p "[↪️] Press any key to continue." < /dev/tty
}

divider() {
    printf '%*s\n' "$(tput cols)" '' | tr ' ' '-'
}

# Asks the user for a yes/no input
# $1 - The question to ask
yes_no_question() {
    while true; do
        read -r -p "$1 ([y]es/[n]o): " opt < /dev/tty
        case "${opt,,}" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) echo "Invalid input. Please enter 'y' or 'n'." ;;
        esac
    done
}

#---------# SCRIPT #---------#

save_user_screen
clear
trap trap_ctrl_c SIGINT

echo "EHUTOOLS INSTALLATION SCRIPT - BY JORJAI"
divider

#----------------------------#

if ! yes_no_question "[❓] Do you want to proceed with the installation of ehu-tools?"; then
    restore_user_screen
    exit 1;
fi

install_ehutools
divider

echo "[✅] Installation complete!"
echo "[ℹ️] This tool uses openconnect for VPN connections."
echo "[ℹ️] Make sure you have openconnect and oathtool installed on your system."

#----------------------------#

press_any_key_to_continue

restore_user_screen
