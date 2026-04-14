[![listed on awesome-euskadi](https://img.shields.io/badge/listed%20on-awesome--euskadi-FFD700?style=for-the-badge&logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNCAxNCI+PGcgZmlsbD0iI0ZGRDcwMCI+PHJlY3QgeD0iNiIgeT0iMCIgd2lkdGg9IjIiIGhlaWdodD0iNiIvPjxyZWN0IHg9IjgiIHk9IjAiIHdpZHRoPSIyIiBoZWlnaHQ9IjIiLz48cmVjdCB4PSI4IiB5PSI2IiB3aWR0aD0iNiIgaGVpZ2h0PSIyIi8+PHJlY3QgeD0iMTIiIHk9IjQiIHdpZHRoPSIyIiBoZWlnaHQ9IjIiLz48cmVjdCB4PSI2IiB5PSI4IiB3aWR0aD0iMiIgaGVpZ2h0PSI2Ii8+PHJlY3QgeD0iNCIgeT0iMTIiIHdpZHRoPSIyIiBoZWlnaHQ9IjIiLz48cmVjdCB4PSIwIiB5PSI2IiB3aWR0aD0iNiIgaGVpZ2h0PSIyIi8+PHJlY3QgeD0iMCIgeT0iOCIgd2lkdGg9IjIiIGhlaWdodD0iMiIvPjwvZz48L3N2Zz4=&labelColor=009B3A)](https://github.com/GeiserX/awesome-euskadi#readme)
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
