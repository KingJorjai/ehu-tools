# 🌐 EHU Tools 🛠  

A set of CLI utilities for managing VPN connections, LDAP authentication, and 2FA for the **University of the Basque Country (EHU)**.  

## 🚀 Features  
- 🔑 **LDAP Authentication**: Store and use your EHU credentials securely.  
- 🛡 **2FA Support**: Generate time-based one-time passwords (TOTP) using `oathtool`.  
- 🌍 **VPN Management**: Connect and disconnect from the EHU VPN with ease.  
- ⚙️ **Interactive Menu**: Simple text-based UI for easy configuration.

## 🔧 Requirements
- bash
- oathtool (for 2FA support)
- Cisco Anyconnect Secure Mobility Client (for VPN connection) (planned to switch to openconnect)

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
