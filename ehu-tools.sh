#!/bin/bash

# Define main paths
BASE_DIR="$HOME/.config/ehu-tools"  # Base directory for the application
VPN_SERVER="vpn.ehu.es"  # EHU VPN server
VPN_PATH_FILE="$BASE_DIR/vpn_path.sh"
CREDENTIAL_FILE="$BASE_DIR/credentials.sh"
SECRET_2FA_FILE="$BASE_DIR/secret_2fa.sh"
LOG_FILE="$BASE_DIR/log"  # VPN log file
CLI_PROMPT=" > "

# Function to save credentials
setup_ldap() {
    echo " 🔑 Enter your LDAP username:"
    read -r -p "$CLI_PROMPT" username
    echo "username=$username" > "$CREDENTIAL_FILE"

    echo "🔐 Enter your LDAP password:"
    read -rs -p "$CLI_PROMPT" password
    echo "password=$password" >> "$CREDENTIAL_FILE"

    unset username password
    echo " ✅ Credentials saved successfully."
}

setup_2fa() {
    echo " 🛡️ Enter your 2FA secret:"
    read -r -p "$CLI_PROMPT" secret_2fa  # Read the 2FA secret

    # Guardar el secreto 2FA en el archivo, asegurándose de que se sobreescriba el archivo
    echo "secret_2fa=$secret_2fa" > "$SECRET_2FA_FILE"

    # Borrar la variable secreta de la memoria
    unset secret_2fa

    # Confirmación
    echo " ✅ 2FA secret saved successfully."
}


get_2fa_token() {
    if [[ -f "$SECRET_2FA_FILE" ]]; then
        source "$SECRET_2FA_FILE"
    fi

    if [[ -n "$secret_2fa" ]]; then
        echo "$(oathtool --totp -b "$secret_2fa")"
    else
        echo ""
    fi
}


setup_vpn_path() {
    echo "Enter your Cisco Anyconnect Secure Mobility Client VPN file path:"
    read -r -p "$CLI_PROMPT" vpn_path

    if [[ ! -f "$vpn_path" ]]; then
        echo " ❌ Invalid VPN client path. File does not exist."
        return 1
    fi

    echo "vpn_path=$vpn_path" > "$VPN_PATH_FILE"

    unset vpn_path
    echo " ✅ VPN path saved successfully."
}

# Function to connect to the VPN
connect_vpn() {
    # Check if credentials exist
    if [[ -f $CREDENTIAL_FILE ]]; then
        source "$CREDENTIAL_FILE"
    fi

    # Check the credentials are valid
    if [[ -z "$username" ]] || [[ -z "$password" ]]; then
        echo " ❌ LDAP credentials not set. Set them up first."
        return
    fi

    # Verify if the VPN binary exists and is executable
    if [[ -f $VPN_PATH_FILE ]]; then
    source "$VPN_PATH_FILE"
    fi

    # Check the path is valid
    if [[ -z "$vpn_path" ]]; then
        echo " ❌ VPN client not found or not executable: $vpn_path"
        return
    fi

    # Check if the oathtool command is available on the system
    if ! command -v oathtool &> /dev/null; then
        echo " ❌ The oathtool command is not installed. Install it before proceeding."
        return
    fi

    if is_vpn_connected; then
        echo " ✅ You are already connected to the VPN."
        return
    fi

    # Obtain the 2FA code using the 2fa tool
    echo " 🔄 Obtaining 2FA code..."
    token="$(get_2fa_token)"
    if [[ -z "$token" ]]; then
        echo "❌ Error obtaining the 2FA code. Ensure 2FA is set correctly."
        return 1
    fi

    echo " 🔑 Connecting to VPN as $username..."

    # Send credentials to the VPN client and start login, logging the process
    {
        echo "[$(date)] Attempting connection with user: $username"
        $vpn_path -s <<EOF
connect $VPN_SERVER
$username
$password
$token
EOF
        echo "[$(date)] Connection successful."
    } >> "$LOG_FILE" 2>&1

    echo " ✅ VPN connected."
    
    # Clear sensitive variables from memory
    unset username password token
}

# Function to check if the VPN is connected
is_vpn_connected() {
    if [[ -z "$vpn_path" ]]; then
        return 1  # VPN path not set, assume not connected
    fi

    "$vpn_path" -s status | grep -q "Connected"
}

# Function to disconnect from the VPN
disconnect_vpn() {
    if [[ -f $VPN_PATH_FILE ]]; then
        source "$VPN_PATH_FILE"
    fi

    if [[ -z "$vpn_path" ]]; then
        echo "❌ VPN client path not set."
        return 1
    fi

    if ! is_vpn_connected; then
        echo " ✅ VPN is already disconnected."
        return 0
    fi

    echo " 🔌 Disconnecting VPN..."
    "$vpn_path" -s disconnect &>> "$LOG_FILE"
    echo " ✅ VPN disconnected."
}



# Function to display the interactive menu
menu() {
    printf '\n%.0s' $(seq 1 $(tput lines))
    while true; do
        clear -x  # Clear screen before displaying the menu
        echo "=============================="
        echo "       🌐 EHU TOOLS 🛠️"
        echo "=============================="
        echo " 1️⃣  Connect to VPN"
        echo " 2️⃣  Set LDAP credentials"
        echo " 3️⃣  Set 2FA secret"
        echo " 4️⃣  Set VPN path"
        echo " 5️⃣  Disconnect from VPN"
        echo " 0️⃣  Exit"
        echo "=============================="
        read -rsn1 option  # Read a single character without requiring Enter
        echo  # Move to a new line

        case "$option" in
            1) connect_vpn ;;
            2) setup_ldap ;;
            3) setup_2fa ;;
            4) setup_vpn_path ;;
            5) disconnect_vpn ;;
            0) echo " 👋 Exiting..."; exit 0 ;;  # Exit the program
            *) echo " ❌ Invalid option, try again." ;;  # Handle invalid input
        esac

        echo " ↪️ Press any key to continue."
        read -rsn1
    done
}

# Run the main menu
menu
