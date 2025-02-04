#!/bin/bash

# Define main paths
BASE_DIR="$HOME/.config/ehu-tools"  # Base directory for the application
VPN_SERVER="vpn.ehu.es"  # EHU VPN server
VPN_CLIENT="/opt/cisco/anyconnect/bin/vpn"
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


# Function to connect to the VPN
connect_vpn() {
    if is_vpn_connected; then
        echo " ✅ You are already connected to the VPN."
        return
    fi

    # Check if credentials exist
    if [[ -f $CREDENTIAL_FILE ]]; then
        source "$CREDENTIAL_FILE"
    fi

    # Check the credentials are valid
    if [[ -z "$username" ]] || [[ -z "$password" ]]; then
        echo " ❌ LDAP credentials not set. Set them up first."
        return
    fi

    # Check if the oathtool command is available on the system
    if ! command -v oathtool &> /dev/null; then
        echo " ❌ The oathtool command is not installed. Install it before proceeding."
        return
    fi

    # Obtain the 2FA code using the 2fa tool
    echo " 🔄 Obtaining 2FA code..."
    token="$(get_2fa_token)"
    if [[ -z "$token" ]]; then
        echo "❌ Error obtaining the 2FA code. Ensure 2FA is set correctly."
        return 1
    fi

    # Check Cisco VPN client
    if [[ ! -x "$VPN_CLIENT" ]]; then
        echo " ❌ Cisco VPN not found or not executable: $VPN_CLIENT."

        # Cisco VPN client not available
        # try to use openconnect
        if command -v openconnect &> /dev/null; then
            echo " 🌐 Falling back to openconnect (has to be run as root)."
            echo " 🔑 Connecting to VPN as $username..."
            (echo "$password"; echo "$token") | sudo openconnect --background --user="$username" --protocol=anyconnect vpn.ehu.eus > /dev/null 2>&1
            echo " ✅ VPN connected."
        else
            echo " ❌ Could not find a compatible VPN client. Read the documentation for more information."
        fi

    # Use Cisco VPN client
    else

        echo " 🔑 Connecting to VPN as $username..."

        # Send credentials to the VPN client and start login, logging the process
        {
            echo "[$(date)] Attempting connection with user: $username"
            $VPN_CLIENT -s <<EOF
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
    fi
}




# Function to check if the VPN is connected
is_vpn_connected() {
    if [[ ! -x "$VPN_CLIENT" ]]; then
        # Check if openconnect is running
        if ps -A | grep -q '[o]penconnect'; then
            # openconnect is running
            return 0
        else
            return 1
        fi
    else
        # Check VPN connection status using the provided VPN client
        "$VPN_CLIENT" -s status | grep -q "Connected"
    fi
}

# Function to disconnect from the VPN
disconnect_vpn() {
    if ! is_vpn_connected; then
        echo " ✅ VPN is already disconnected."
        return 0
    fi

    if [[ ! -x "$VPN_CLIENT" ]]; then
        echo " ❌ Cisco VPN not found or not executable: $VPN_CLIENT."

        # Cisco VPN client not available
        # try to use openconnect
        if command -v openconnect &> /dev/null; then
            echo " 🌐 Falling back to openconnect (has to be run as root)."
            sudo pkill -SIGINT openconnect
            echo " 🔌 Disconnecting VPN..."
            sleep 1 # Wait for the process to finish
            echo " ✅ VPN disconnected."

        else
            echo " ❌ Could not find a compatible VPN client. Read the documentation for more information."
        fi
    else
        echo " 🔌 Disconnecting VPN..."
        "$VPN_CLIENT" -s disconnect &>> "$LOG_FILE"
        echo " ✅ VPN disconnected."
    fi

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
        echo " 2️⃣  Disconnect from VPN"
        echo " 3️⃣  Set LDAP credentials"
        echo " 4️⃣  Set 2FA secret"
        echo " 0️⃣  Exit"
        echo "=============================="
        read -rsn1 option  # Read a single character without requiring Enter
        echo  # Move to a new line

        case "$option" in
            1) connect_vpn ;;
            2) disconnect_vpn ;;
            3) setup_ldap ;;
            4) setup_2fa ;;
            0) echo " 👋 Exiting..."; exit 0 ;;  # Exit the program
            *) echo " ❌ Invalid option, try again." ;;  # Handle invalid input
        esac

        echo " ↪️ Press any key to continue."
        read -rsn1
    done
}

##### MAIN PROGRAM #####

# Create config folder if not already
mkdir -p $BASE_DIR

# Run the main menu
menu
