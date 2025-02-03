#!/bin/bash

# Define installation path
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="ehu-tools"
SCRIPT_URL="https://raw.githubusercontent.com/KingJorjai/ehu-tools/refs/heads/main/ehu-tools.sh"

# Ensure the installation directory exists
mkdir -p "$INSTALL_DIR"

# Download the script
echo "📥 Downloading $SCRIPT_NAME..."
curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/$SCRIPT_NAME"

# Make it executable
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# Add to PATH if not already included
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$HOME/.bashrc"
    echo "🔧 Added $INSTALL_DIR to PATH (restart your terminal or run 'source ~/.bashrc')"
fi

echo "✅ Installation complete. You can now run '$SCRIPT_NAME' from anywhere."
