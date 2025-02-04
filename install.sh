#!/bin/bash

#---------# VARIABLES #---------#

# PACKAGE INFO
INSTALL_DIR="$HOME/.local/bin"
INSTALL_NAME="ehu-tools"

# GITHUB
GITHUB_BASE_URL="https://raw.githubusercontent.com/KingJorjai/ehu-tools/refs/heads/"
GITHUB_EHUTOOLS_URL="$GITHUB_BASE_URL/main/ehu-tools.sh"
GITHUB_CISCOINSTALL_URL="$GITHUB_BASE_URL/develop/cisco_install.sh"

# CISCO
CISCO_VPN_FILE="/opt/cisco/anyconnect/bin/vpn"

#---------# EHUTOOLS FUNCTIONS #---------#

install_ehutools() {
    # Ensure the installation directory exists
    mkdir -p "$INSTALL_DIR"

    # Download the script
    echo "[📥] Downloading $INSTALL_NAME..."
    curl -fsSL "$GITHUB_EHUTOOLS_URL" -o "$INSTALL_DIR/$INSTALL_NAME"

    # Make it executable
    chmod +x "$INSTALL_DIR/$INSTALL_NAME"

    # Add to PATH if not already included
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$HOME/.bashrc"
        echo "[🔧] Added $INSTALL_DIR to PATH (restart your terminal or run 'source ~/.bashrc')"
    fi

    echo "[✅] Installation complete. You can now run '$INSTALL_NAME' from anywhere."
}

#---------# CISCO FUNCTIONS #---------#

install_cisco() {
    curl -SsL $GITHUB_CISCOINSTALL_URL | bash
}

is_cisco_installed() {
    [[ -x "$CISCO_VPN_FILE" ]]
}


#---------# SCRIPT #---------#
install_ehutools
