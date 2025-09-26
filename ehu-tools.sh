#!/bin/bash

#---------# VARIABLES #---------#

# EHUTOOLS
BASE_DIR="$HOME/.config/ehu-tools"
CREDENTIAL_FILE="$BASE_DIR/credentials.sh"
SECRET_2FA_FILE="$BASE_DIR/secret_2fa.sh"
SSH_SERVERS_FILE="$BASE_DIR/ssh_servers.csv"

# MISCELLANEOUS
CLI_PROMPT=" > "

#---------# UTIL FUNCTIONS #---------#

# Asks the user for a yes/no input
# $1 - The question to ask
yes_no_question() {
    while true; do
        read -r -p "$1 ([y]es/[n]o): " opt < /dev/tty
        case "${opt,,}" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) echo "[❌] Invalid input. Please enter 'y' or 'n'." ;;
        esac
    done
}

number_to_emoji() {
    local num="$1"
    local emoji_digits=("0️⃣" "1️⃣" "2️⃣" "3️⃣" "4️⃣" "5️⃣" "6️⃣" "7️⃣" "8️⃣" "9️⃣")
    local result=""

    for (( i=0; i<${#num}; i++ )); do
        digit="${num:i:1}"
        result+="${emoji_digits[digit]}"
    done

    echo "$result"
}

press_any_key_to_continue() {
    echo "[↪️] Press any key to continue."
    read -rsn1
}

# FILE EXISTS

credential_file_exists() {
    [[ -f $CREDENTIAL_FILE ]]
}

totp_secret_file_exists() {
    [[ -f $SECRET_2FA_FILE ]]
}

ssh_connection_file_exists() {
    [[ -f $SSH_SERVERS_FILE ]]
}

# CONFIG VALIDATION

are_credentials_valid() {
    # Check if credentials exist
    if credential_file_exists ; then
        source "$CREDENTIAL_FILE"
    fi

    [[ -n "$username" && -n "$password" ]]
}

is_totp_secret_valid() {
    # Check if file exists
    if totp_secret_file_exists; then
        source $SECRET_2FA_FILE
    fi

    [[ -n "$secret_2fa" ]]
}


#---------# SETUP FUNCTIONS #---------#

setup_ldap() {
    echo "[🔑] Enter your LDAP username:"
    read -r -p "$CLI_PROMPT" username
    echo "username=$username" > "$CREDENTIAL_FILE"

    echo "[🔐] Enter your LDAP password:"
    read -rs -p "$CLI_PROMPT" password
    echo "password=$password" >> "$CREDENTIAL_FILE"

    unset username password
    echo "[✅] Credentials saved successfully."
}

setup_2fa() {
    echo "[🛡️] Enter your 2FA secret:"
    read -r -p "$CLI_PROMPT" secret_2fa  # Read the 2FA secret

    # Save the secret
    echo "secret_2fa=$secret_2fa" > "$SECRET_2FA_FILE"

    # Clear the secret from the memory
    unset secret_2fa

    # Confirmation
    echo "[✅] 2FA secret saved successfully."
}

on_launch_config_check() {
    if ! are_credentials_valid; then
        if yes_no_question "[⚠️] LDAP credentials are not set up. Do you want to do it now?"; then
            clear -x
            setup_ldap
        fi
    fi

    clear -x

    if ! is_totp_secret_valid; then
        if yes_no_question "[⚠️] 2FA is not set up. Do you want to do it now?"; then
            clear -x
            setup_2fa
        fi
    fi
}

#---------# CONNECTION FUNCTIONS #---------#

get_2fa_token() {
    if totp_secret_file_exists ; then
        source "$SECRET_2FA_FILE"
    fi

    if [[ -n "$secret_2fa" ]]; then
        echo "$(oathtool --totp -b "$secret_2fa")"
    else
        echo ""
    fi
}

is_vpn_connected() {
    # Check if openconnect is running
    if ps -A | grep -q '[o]penconnect'; then
        # openconnect is running
        return 0
    else
        return 1
    fi
}

connect_vpn() {
    # Check if already connected
    if is_vpn_connected; then
        echo "[✅] You are already connected to the VPN."
        return
    fi

    # Check the credentials are valid
    if ! are_credentials_valid; then
        echo "[❌] LDAP credentials not set. Set them up first."
        return
    fi

    # Load the user and the password
    source "$CREDENTIAL_FILE"

    # Check if the oathtool command is available on the system
    if ! command -v oathtool &> /dev/null; then
        echo "[❌] The oathtool command is not installed. Install it before proceeding."
        return
    fi

    # Check if openconnect is available
    if ! command -v openconnect &> /dev/null; then
        echo "[❌] openconnect is not installed. Please install it first."
        return
    fi

    # Obtain the 2FA code
    echo "[🔄] Obtaining 2FA code..."
    token="$(get_2fa_token)"
    if [[ -z "$token" ]]; then
        echo "[❌] Error obtaining the 2FA code. Ensure 2FA is set correctly."
        return 1
    fi

    echo "[🔑] Connecting to VPN as $username..."
    (echo "$password"; echo "$token") | sudo openconnect --background --user="$username" --protocol=fortinet vpn2.ehu.eus > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "[✅] VPN connected."
    else
        echo "[❌] Failed to connect to VPN."
    fi

    # Clear sensitive variables from memory
    unset username password token
}

disconnect_vpn() {
    # Check if already disconnected
    if ! is_vpn_connected; then
        echo "[✅] VPN is already disconnected."
        return 0
    fi

    echo "[🔌] Disconnecting VPN..."
    sudo pkill -SIGINT openconnect
    sleep 1 # Wait for the process to finish
    
    if ! is_vpn_connected; then
        echo "[✅] VPN disconnected."
    else
        echo "[❌] Failed to disconnect VPN."
    fi
}

#---------# SSH MANAGER FUNCTIONS #---------#

ssh_connect() {
    # Check arguments
    if [ -z "$1" ] || [ -z "$2" ]; then
        return 1
    fi

    local user="$1"
    local host="$2"
    local port="${3:-22}"  # Optional port, default 22

    # Create the connection
    printf "[⚠️] "
    ssh -p "$port" "$user@$host"

    # Check if the command failed
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        press_any_key_to_continue
        return 1
    else
        return 0
    fi
}


# Function to add an SSH server to the CSV file
# $1 - user
# $2 - host
# ($3) - port
add_ssh_server_worker() {
    local user="$1"
    local host="$2"
    local port="${3:-22}"  # Optional port, defaults to 22

    if [[ -z "$user" || -z "$host" ]]; then
        echo "[❌] User and host are required parameters."
        return 2
    fi

    # Create the file with a header if it doesn't exist
    if ! ssh_connection_file_exists; then
        echo "user,host,port" > "$SSH_SERVERS_FILE"
    fi

    # Check if the connection already exists
    if grep -q "^$user,$host," "$SSH_SERVERS_FILE"; then
        echo "[⚠️] The SSH connection $user@$host already exists."
        return 1
    fi

    # Add the new connection
    echo "$user,$host,$port" >> "$SSH_SERVERS_FILE"
    echo "[✅] SSH connection $user@$host added successfully."
}

add_ssh_server_frontend() {
    echo "[👤] Introduce the user:"
    read -r -p "$CLI_PROMPT" user
    echo "[💻] Introduce the host:"
    read -r -p "$CLI_PROMPT" host
    echo "[⚡] Introduce the port (leave empty for 22):"
    read -r -p "$CLI_PROMPT" port

    add_ssh_server_worker $user $host $port
}

# Function to remove an SSH server from the CSV file
# $1 - user
# $2 - host
remove_ssh_server() {
    local user="$1"
    local host="$2"

    if [[ -z "$user" || -z "$host" ]]; then
        echo "[❌] User and host are required parameters."
        return 2
    fi

    if ! ssh_connection_file_exists ; then
        echo "[⚠️] No saved SSH servers found."
        return 1
    fi

    # Create a temporary file without the matching line and overwrite the original file
    grep -v "^$user,$host," "$SSH_SERVERS_FILE" > temp.csv && mv temp.csv "$SSH_SERVERS_FILE"

    # Reload SSH servers after deletion
    list_ssh_servers

    echo "[✅] SSH connection ${user}@${host} removed successfully."
}

# Updates the values of the ssh connection list
list_ssh_servers() {
    local index=1  # Index for the keys
    local user
    local host
    local port

    # Clear the arrays before reloading
    unset SSH_CONNECTIONS_CONNECT
    unset SSH_CONNECTIONS_REMOVE

    # Check the file exists
    if [ ! -f "$SSH_SERVERS_FILE" ]; then
        return 1
    fi

    # Read CSV file
    while IFS=, read -r user host port; do
        # Omit first line (header)
        if [[ "$user" != "user" ]]; then
            description="${user}@${host}"

            command_connect="ssh_connect ${user} ${host} ${port}"
            command_remove="remove_ssh_server ${user} ${host}; press_any_key_to_continue"

            SSH_CONNECTIONS_CONNECT["$index"]="${description}:${command_connect}"
            SSH_CONNECTIONS_REMOVE["$index"]="${description}:${command_remove}"
            ((index++))
        fi
    done < "$SSH_SERVERS_FILE"
}

#---------# CLI FUNCTIONS #---------#

create_menu() {
    while true; do
        local -n menu_options=$1

        clear -x  # Clear screen before displaying the menu
        echo "=============================="
        echo "       🌐 EHU TOOLS 🛠️"
        echo "=============================="

        # Print each option
        for key in $(printf "%s\n" "${!menu_options[@]}" | sort -n); do
            emoji_key=$(number_to_emoji "$key")
            echo " $emoji_key  ${menu_options[$key]%%:*}"  # Show only the description
        done

        echo " 0️⃣  Back"
        echo "=============================="

        if [[ ${#menu_options[@]} -eq 0 ]]; then
            echo "[❌] No options available."
            press_any_key_to_continue
            return 1
        fi

        read -r -p "$CLI_PROMPT" option # Read user input
        echo  # Move to a new line

        if [[ "$option" == "0" ]]; then
            return 0
        elif [[ -n "${menu_options[$option]}" ]]; then
            eval "${menu_options[$option]#*:}"  # Execute the associated command
        else
            echo "[❌] Invalid option, try again."
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
    [1]="Connect to SSH server:list_ssh_servers; create_menu SSH_CONNECTIONS_CONNECT"
    [2]="Add new SSH server:add_ssh_server_frontend; press_any_key_to_continue"
    [3]="Remove SSH server:list_ssh_servers; create_menu SSH_CONNECTIONS_REMOVE"
    )
    create_menu options
}

#---------# SCRIPT #---------#

# Prepare blank canvas
printf '\n%.0s' $(seq 1 $(tput lines))
clear -x

# Create config folder if not already
mkdir -p $BASE_DIR

# Run on launch config checks
on_launch_config_check

# Run the main menu
main_menu
clear -x
