# 🌐 EHU Tools 🛠  

A set of CLI utilities for managing LDAP authentication, VPN connections, and 2FA for the **University of the Basque Country (UPV/EHU)**.  

> [!WARNING]
> Due to the VPN system of the University recently changing, this feature is not working at the moment.
> Migration from `anyconnect` to `fortinet` is planned for the next update.

## 🚀 Features  
- 🔑 **LDAP Authentication**: Store and use your EHU credentials securely.  
- 🛡 **2FA Support**: Generate time-based one-time passwords (TOTP) using `oathtool`.  
- 🌍 **VPN Management**: Connect and disconnect from the EHU VPN with ease.  
- ⚙️ **Interactive Menu**: Simple text-based UI for easy configuration.

## 🔧 Requirements
- `bash`
- `oathtool` (for 2FA support)
- One of the following VPN Clients
  - ~~`Cisco Anyconnect Secure Mobility Client` (no root required)~~
  - `openconnect` (root required) 

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
