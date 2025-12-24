# EthSign SSH Build Tool - Mac/Hackintosh Setup Guide

## 🖥️ How to Enable SSH on Your Mac/Hackintosh

### Step 1: Enable Remote Login (SSH Server)

1. Open **System Preferences** (or **System Settings** on macOS Ventura+)
2. Go to **Sharing** (or **General → Sharing**)
3. Turn ON **Remote Login**
4. Under "Allow access for:", select:
   - **All users** (easy but less secure)
   - Or **Only these users** and add your username

### Step 2: Find Your Mac's IP Address

**Method 1: From Terminal**
```bash
# Open Terminal and run:
ifconfig | grep "inet " | grep -v 127.0.0.1

# Look for something like: inet 192.168.1.XXX
```

**Method 2: From System Preferences**
1. Go to **System Preferences → Network**
2. Select your active connection (Wi-Fi or Ethernet)
3. Your IP address is shown (e.g., `192.168.1.105`)

**Method 3: Quick Command**
```bash
# This returns your local IP directly:
ipconfig getifaddr en0    # For Wi-Fi
ipconfig getifaddr en1    # For Ethernet
```

### Step 3: Test SSH Connection

From your Windows PC, open PowerShell and test:
```powershell
ssh username@192.168.1.XXX
```

Replace:
- `username` with your Mac login username
- `192.168.1.XXX` with your Mac's IP

---

## 🔧 Hackintosh Specific Notes

If you're using a Hackintosh:

1. **Same process as Mac** - SSH setup is identical
2. **Check Network is working** - Make sure your Hackintosh has network connectivity
3. **Firewall** - Disable or configure macOS firewall to allow SSH:
   - System Preferences → Security & Privacy → Firewall → Firewall Options
   - Ensure "Block all incoming connections" is OFF
   - Or add Terminal/sshd to allowed apps

---

## 🔍 Finding Devices on Your Network

If you don't know your Mac's IP, you can scan from Windows:

### Using built-in tools:
```powershell
# Scan common subnet (change 192.168.1 to match your network)
1..254 | ForEach-Object { 
    $ip = "192.168.1.$_"
    if (Test-Connection -ComputerName $ip -Count 1 -Quiet -TimeoutSeconds 1) {
        Write-Host "Found: $ip"
    }
}
```

### Using nmap (if installed):
```powershell
nmap -sn 192.168.1.0/24
```

---

## 📋 Requirements on Your Mac

Make sure these are installed on your Mac/Hackintosh:

1. **Xcode** - Install from App Store or Apple Developer site
2. **Command Line Tools** - Run: `xcode-select --install`
3. **Git** - Usually included with Command Line Tools

### Verify Xcode:
```bash
xcodebuild -version
# Should show: Xcode X.X Build version XXXXX
```

---

## 🚀 Quick Setup Checklist

- [ ] SSH enabled on Mac (System Preferences → Sharing → Remote Login)
- [ ] Know your Mac's IP address
- [ ] Can ping Mac from Windows: `ping 192.168.1.XXX`
- [ ] Can SSH from Windows: `ssh user@192.168.1.XXX`
- [ ] Xcode installed on Mac
- [ ] Git installed on Mac

---

## 🔐 Recommended: Use SSH Key Authentication

Instead of password, set up SSH keys for better security:

### On Windows (PowerShell):
```powershell
# Generate SSH key
ssh-keygen -t rsa -b 4096

# Copy to Mac
type $env:USERPROFILE\.ssh\id_rsa.pub | ssh user@192.168.1.XXX "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

Then in the tool configuration, set:
- **SSH Key Path**: `C:\Users\YourName\.ssh\id_rsa`
- Leave **Password** blank

---

## 💡 Troubleshooting

### "Connection refused"
- SSH not enabled on Mac
- Firewall blocking port 22

### "Permission denied"
- Wrong username or password
- User not allowed in Remote Login settings

### "Host unreachable"
- Wrong IP address
- Mac not on same network
- Check if Mac is asleep (wake it up)

### "xcodebuild not found"
- Xcode not installed
- Run: `sudo xcode-select -s /Applications/Xcode.app`
