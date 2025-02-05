#!/bin/bash

#---------# VARIABLES #---------#

BASE_DIR="$HOME/.config/ehu-tools"  # Base directory for the application
VPN_SERVER="vpn.ehu.es"  # EHU VPN server
VPN_CLIENT="/opt/cisco/anyconnect/bin/vpn"
CREDENTIAL_FILE="$BASE_DIR/credentials.sh"
SECRET_2FA_FILE="$BASE_DIR/secret_2fa.sh"
LOG_FILE="$BASE_DIR/log"  # VPN log file
CLI_PROMPT=" > "

#---------# SETUP FUNCTIONS #---------#

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

#---------# CONNECTION FUNCTIONS #---------#

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

connect_vpn() {
    # Check if already connected
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

    # Obtain the 2FA code
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

disconnect_vpn() {
    # Check if already disconnected
    if ! is_vpn_connected; then
        echo " ✅ VPN is already disconnected."
        return 0
    fi

    # Check Cisco VPN client
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

#---------# SSH FUNCTIONS #---------#

ssh_connect() {
    # Check arguments
    if [ -z "$1" ] || [ -z "$2" ]; then
        return 1
    fi

    local user="$1"
    local host="$2"
    local port="${3:-22}"  # Optional port, default 22

    # Conectar por SSH
    ssh -p "$port" "$user@$host"
}


#---------# UTIL FUNCTIONS #---------#
press_any_key_to_continue() {
    echo " ↪️ Press any key to continue."
    read -rsn1
            }

#---------# CLI FUNCTIONS #---------#

create_menu() {
    local -n menu_options=$1  # Array asociativo con las opciones y sus comandos

    while true; do
        clear -x  # Clear screen before displaying the menu
        echo "=============================="
        echo "       🌐 EHU TOOLS 🛠️"
        echo "=============================="

        for key in $(printf "%s\n" "${!menu_options[@]}" | sort -n); do
            echo " $key️⃣  ${menu_options[$key]%%:*}"  # Muestra solo la descripción
        done

        echo " 0️⃣  Back"
        echo "=============================="
        read -rsn1 option  # Read a single character without requiring Enter
        echo  # Move to a new line

        if [[ "$option" == "0" ]]; then
            return 0
        elif [[ -n "${menu_options[$option]}" ]]; then
            eval "${menu_options[$option]#*:}"  # Ejecuta el comando asociado
        else
            echo " ❌ Invalid option, try again."
        fi

    done
}

main_menu() {
    declare -A options=(
    [1]="Connect to VPN:connect_vpn; press_any_key_to_continue"
    [2]="Disconnect from VPN:disconnect_vpn; press_any_key_to_continue"
    [3]="Manage SSH Servers:ssh_menu"
    [4]="Set LDAP credentials:setup_ldap; press_any_key_to_continue"
    [5]="Set 2FA secret:setup_2fa"
    )
    create_menu options
}

ssh_menu(){
    declare -A options=(
    [1]="Connect to SSH server:ssh_list_menu connect"
    [2]="Add new SSH server:ssh_list_menu add"
    [3]="Remove SSH server:ssh_list_menu remove"
    )
    create_menu options
}

#---------# SCRIPT #---------#

# Prepare blank canvas
printf '\n%.0s' $(seq 1 $(tput lines))

# Create config folder if not already
mkdir -p $BASE_DIR

# Run the main menu
main_menu
