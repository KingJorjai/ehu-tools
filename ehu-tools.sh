#!/bin/bash

#---------# VARIABLES #---------#

# VPN
VPN_SERVER="vpn.ehu.es"
VPN_CLIENT="/opt/cisco/anyconnect/bin/vpn"

# EHUTOOLS
BASE_DIR="$HOME/.config/ehu-tools"
CREDENTIAL_FILE="$BASE_DIR/credentials.sh"
SECRET_2FA_FILE="$BASE_DIR/secret_2fa.sh"
SSH_SERVERS_FILE="$BASE_DIR/ssh_servers.csv"
LOG_FILE="$BASE_DIR/log"  # VPN log file

# MISCELLANEOUS
CLI_PROMPT=" > "

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
        echo "[✅] You are already connected to the VPN."
        return
    fi

    # Check if credentials exist
    if [[ -f $CREDENTIAL_FILE ]]; then
        source "$CREDENTIAL_FILE"
    fi

    # Check the credentials are valid
    if [[ -z "$username" ]] || [[ -z "$password" ]]; then
        echo "[❌] LDAP credentials not set. Set them up first."
        return
    fi

    # Check if the oathtool command is available on the system
    if ! command -v oathtool &> /dev/null; then
        echo "[❌] The oathtool command is not installed. Install it before proceeding."
        return
    fi

    # Obtain the 2FA code
    echo "[🔄] Obtaining 2FA code..."
    token="$(get_2fa_token)"
    if [[ -z "$token" ]]; then
        echo "[❌] Error obtaining the 2FA code. Ensure 2FA is set correctly."
        return 1
    fi

    # Check Cisco VPN client
    if [[ ! -x "$VPN_CLIENT" ]]; then
        echo "[❌] Cisco VPN not found or not executable: $VPN_CLIENT."

        # Cisco VPN client not available
        # try to use openconnect
        if command -v openconnect &> /dev/null; then
            echo "[🌐] Falling back to openconnect (has to be run as root)."
            echo "[🔑] Connecting to VPN as $username..."
            (echo "$password"; echo "$token") | sudo openconnect --background --user="$username" --protocol=anyconnect vpn.ehu.eus > /dev/null 2>&1
            echo "[✅] VPN connected."
        else
            echo "[❌] Could not find a compatible VPN client. Read the documentation for more information."
        fi

    # Use Cisco VPN client
    else

        echo "[🔑] Connecting to VPN as $username..."

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

        echo "[✅] VPN connected."
    
        # Clear sensitive variables from memory
        unset username password token
    fi
}

disconnect_vpn() {
    # Check if already disconnected
    if ! is_vpn_connected; then
        echo "[✅] VPN is already disconnected."
        return 0
    fi

    # Check Cisco VPN client
    if [[ ! -x "$VPN_CLIENT" ]]; then
        echo "[❌] Cisco VPN not found or not executable: $VPN_CLIENT."

        # Cisco VPN client not available
        # try to use openconnect
        if command -v openconnect &> /dev/null; then
            echo "[🌐] Falling back to openconnect (has to be run as root)."
            sudo pkill -SIGINT openconnect
            echo "[🔌] Disconnecting VPN..."
            sleep 1 # Wait for the process to finish
            echo "[✅] VPN disconnected."

        else
            echo "[❌] Could not find a compatible VPN client. Read the documentation for more information."
        fi
    else
        echo "[🔌] Disconnecting VPN..."
        "$VPN_CLIENT" -s disconnect &>> "$LOG_FILE"
        echo "[✅] VPN disconnected."
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
    if [[ ! -f "$SSH_SERVERS_FILE" ]]; then
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

    if [[ ! -f "$SSH_SERVERS_FILE" ]]; then
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


#---------# UTIL FUNCTIONS #---------#

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

# Create config folder if not already
mkdir -p $BASE_DIR

# Run the main menu
main_menu
clear -x
