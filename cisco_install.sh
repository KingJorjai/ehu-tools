#!/bin/bash

#---------# VARIABLES #---------#

URL="https://www.ehu.eus/documents/1870470/8671861/anyconnect-linux64-4.10.08029-predeploy-k9.tar.gz/f9bb66dc-2a67-a2f2-631f-15c82c7f1185?t=1718180076427"
FILE="$HOME/anyconnect-linux64-4.10.08029-predeploy-k9.tar.gz"
FOLDER="$HOME/anyconnect-linux64-4.10.08029"

#---------# FUNCTIONS #---------#

divider() {
    printf '%*s\n' "$(tput cols)" '' | tr ' ' '-'
}

remove_installation_files() {
    echo "[♻️] Cleaning up installation files..."
    rm -rf "$FOLDER" "$FILE" || echo "Error removing the files."
}

download_cisco() {
    echo "[📥] Downloading Cisco Anyconnect Secure Mobility Client..."
    divider
    wget -O "$FILE" "$URL"
    divider

    if [ $? -ne 0 ]; then
        echo "[⚠️] Error downloading the file."
        remove_installation_files
        exit 1
    fi
}

extract_cisco() {
    echo "[↕️] Extracting the file..."
    if tar -xzf "$FILE" -C "$HOME"; then
        echo "[✅] File extracted successfully"
    else
        echo "[⚠️] Error extracting the file."
        remove_installation_files
        exit 1
    fi
}

install_cisco() {
    prev_dir=$(pwd)

    if cd "$FOLDER/vpn/"; then
        echo "[🌐] Installing Cisco Anyconnect Secure Mobility Client..."
        divider
        sudo ./vpn_install.sh
        divider
        install_status=$?
    else
        echo "[⚠️] Error attempting to start Cisco Anyconnect Secure Mobility Client installation."
        remove_installation_files
        exit 1
    fi

    cd "$prev_dir"

    if [ $install_status -ne 0 ]; then
        echo "[⚠️] Error during installation."
        remove_installation_files
        exit 1
    fi

    echo "[✅] Installation completed successfully."
}

#---------# SCRIPT #---------#

download_cisco
extract_cisco
install_cisco

remove_installation_files
