# 🌐 EHU Tools 🛠  

A set of CLI utilities for managing LDAP authentication, VPN connections, and 2FA for the **University of the Basque Country (UPV/EHU)**.  

## 🚀 Features  
- 🔑 **LDAP Authentication**: Store and use your EHU credentials securely.  
- 🛡 **2FA Support**: Generate time-based one-time passwords (TOTP) using `oathtool`.  
- 🌍 **VPN Management**: Connect and disconnect from the EHU VPN using Fortinet protocol.  
- 📡 **SSH Management**: Save and manage SSH server connections.
- ⚙️ **Interactive Menu**: Simple text-based UI for easy configuration.

## 🔧 Requirements
- `bash`
- `oathtool` (for 2FA support)
- `openconnect` (for VPN connections - requires root privileges)

## 📥 Installation  

Run the following command to download and install EHU Tools:  

```bash
curl -sSL https://raw.githubusercontent.com/KingJorjai/ehu-tools/main/install.sh | bash
```
Alternatively, you can clone the repository and install manually:
```bash
git clone https://github.com/KingJorjai/ehu-tools.git
cd ehu-tools
bash install.sh
```

## 🛠 Usage

After installation, simply run:
```bash
ehu-tools
```

The tool provides an interactive menu with the following options:
1. **Connect to VPN** - Establish VPN connection using openconnect
2. **Disconnect from VPN** - Terminate VPN connection  
3. **Manage SSH Servers** - Add, remove, or connect to saved SSH servers
4. **Set LDAP credentials** - Configure your EHU username and password
5. **Set 2FA secret** - Configure your TOTP secret for 2FA

## 🔐 Security Notes

- Credentials are stored locally in `~/.config/ehu-tools/`
- All sensitive data is handled securely and cleared from memory after use
- VPN connections require root privileges due to openconnect requirements

## 🤝 Contributing

Feel free to open issues and submit pull requests to improve this tool!
