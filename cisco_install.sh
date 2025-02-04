#!/bin/bash

#---------# VARIABLES #---------#

URL="https://www.ehu.eus/documents/1870470/8671861/anyconnect-linux64-4.10.08029-predeploy-k9.tar.gz/f9bb66dc-2a67-a2f2-631f-15c82c7f1185?t=1718180076427"
FILE="$HOME/anyconnect-linux64-4.10.08029-predeploy-k9.tar.gz"
FOLDER="$HOME/anyconnect-linux64-4.10.08029"

#---------# FUNCTIONS #---------#

remove_installation_files() {
    echo "Cleaning up installation files..."
    rm -rf "$FOLDER" "$FILE" || echo "Error removing the files."
}

download_anyconnect() {
    echo "Downloading AnyConnect..."
    wget -O "$FILE" "$URL"

    if [ $? -ne 0 ]; then
        echo "Error downloading the file."
        remove_installation_files
        exit 1
    fi
}

extract_anyconnect() {
    echo "Extracting the file..."
    if tar -xzf "$FILE" -C "$HOME"; then
        echo "File extracted successfully"
    else
        echo "Error extracting the file."
        remove_installation_files
        exit 1
    fi
}

install_anyconnect() {
    prev_dir=$(pwd)

    if cd "$FOLDER/vpn/"; then
        echo "Installing AnyConnect..."
        echo "y" | sudo ./vpn_install.sh
        install_status=$?
    else
        echo "Error attempting to start AnyConnect installation."
        remove_installation_files
        exit 1
    fi

    cd "$prev_dir"

    if [ $install_status -ne 0 ]; then
        echo "Error during installation."
        remove_installation_files
        exit 1
    fi

    echo "Installation completed successfully."
}

#---------# SCRIPT #---------#

download_anyconnect
extract_anyconnect
install_anyconnect

remove_installation_files
