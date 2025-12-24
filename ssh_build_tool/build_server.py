#!/usr/bin/env python3
"""
EthSign SSH Build Tool - Interactive CLI
A menu-based CLI tool to remotely build iOS apps via SSH and serve the compiled IPA
"""

import os
import sys
import time
import json
import socket
import threading
import subprocess
import http.server
import socketserver
import concurrent.futures
from pathlib import Path
from typing import Optional, List, Tuple
from datetime import datetime

try:
    import paramiko
except ImportError:
    print("Installing required package: paramiko...")
    os.system("python -m pip install paramiko --quiet")
    import paramiko


# ═══════════════════════════════════════════════════════════════════════════════
# COLORS AND STYLING
# ═══════════════════════════════════════════════════════════════════════════════

class Colors:
    """ANSI color codes for terminal output"""
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    WHITE = '\033[97m'
    GRAY = '\033[90m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    DIM = '\033[2m'
    
    @staticmethod
    def gradient(text: str) -> str:
        """Apply gradient-like effect to text"""
        colors = ['\033[95m', '\033[94m', '\033[96m', '\033[92m']
        result = ""
        for i, char in enumerate(text):
            result += colors[i % len(colors)] + char
        return result + Colors.ENDC


def clear_screen():
    """Clear the terminal screen"""
    os.system('cls' if os.name == 'nt' else 'clear')


def print_header():
    """Print the application header"""
    clear_screen()
    print(f"""
{Colors.CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║   {Colors.GREEN}███████╗████████╗██╗  ██╗███████╗██╗ ██████╗ ███╗   ██╗{Colors.CYAN}                    ║
║   {Colors.GREEN}██╔════╝╚══██╔══╝██║  ██║██╔════╝██║██╔════╝ ████╗  ██║{Colors.CYAN}                    ║
║   {Colors.GREEN}█████╗     ██║   ███████║███████╗██║██║  ███╗██╔██╗ ██║{Colors.CYAN}                    ║
║   {Colors.GREEN}██╔══╝     ██║   ██╔══██║╚════██║██║██║   ██║██║╚██╗██║{Colors.CYAN}                    ║
║   {Colors.GREEN}███████╗   ██║   ██║  ██║███████║██║╚██████╔╝██║ ╚████║{Colors.CYAN}                    ║
║   {Colors.GREEN}╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝{Colors.CYAN}                    ║
║                                                                               ║
║                    {Colors.WHITE}SSH Build Tool & IPA Server v2.0{Colors.CYAN}                         ║
║                    {Colors.GRAY}Remote Xcode Build System{Colors.CYAN}                                 ║
╚═══════════════════════════════════════════════════════════════════════════════╝{Colors.ENDC}
""")


def print_box(title: str, content: list, width: int = 60):
    """Print a styled box with content"""
    print(f"\n{Colors.CYAN}┌{'─' * (width - 2)}┐{Colors.ENDC}")
    print(f"{Colors.CYAN}│{Colors.WHITE}{Colors.BOLD} {title.center(width - 4)} {Colors.CYAN}│{Colors.ENDC}")
    print(f"{Colors.CYAN}├{'─' * (width - 2)}┤{Colors.ENDC}")
    for line in content:
        padded = line[:width-4].ljust(width - 4)
        print(f"{Colors.CYAN}│{Colors.ENDC} {padded} {Colors.CYAN}│{Colors.ENDC}")
    print(f"{Colors.CYAN}└{'─' * (width - 2)}┘{Colors.ENDC}")


# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION MANAGER
# ═══════════════════════════════════════════════════════════════════════════════

class ConfigManager:
    """Manages application configuration"""
    
    CONFIG_FILE = "config.json"
    
    DEFAULT_CONFIG = {
        "ssh": {
            "host": "",
            "port": 22,
            "username": "",
            "password": "",
            "key_path": ""
        },
        "build": {
            "repo_url": "https://github.com/master726/EthSign.git",
            "branch": "main",
            "target_dir": "~/EthSign-build",
            "use_makefile": True,
            "project_name": "Ksign"
        },
        "server": {
            "port": 8080,
            "auto_start": True
        },
        "output": {
            "local_dir": "./build_output"
        }
    }
    
    def __init__(self):
        self.config = self.load()
    
    def load(self) -> dict:
        """Load configuration from file"""
        if os.path.exists(self.CONFIG_FILE):
            try:
                with open(self.CONFIG_FILE, 'r') as f:
                    loaded = json.load(f)
                    # Merge with defaults to ensure all keys exist
                    return self._merge_config(self.DEFAULT_CONFIG.copy(), loaded)
            except:
                pass
        return self.DEFAULT_CONFIG.copy()
    
    def _merge_config(self, default: dict, loaded: dict) -> dict:
        """Deep merge loaded config with defaults"""
        result = default.copy()
        for key, value in loaded.items():
            if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                result[key] = self._merge_config(result[key], value)
            else:
                result[key] = value
        return result
    
    def save(self):
        """Save configuration to file"""
        with open(self.CONFIG_FILE, 'w') as f:
            json.dump(self.config, f, indent=2)
        print(f"\n{Colors.GREEN}✅ Configuration saved!{Colors.ENDC}")
    
    def get(self, *keys):
        """Get a configuration value by keys"""
        value = self.config
        for key in keys:
            value = value.get(key, "")
        return value
    
    def set(self, value, *keys):
        """Set a configuration value by keys"""
        config = self.config
        for key in keys[:-1]:
            config = config.setdefault(key, {})
        config[keys[-1]] = value


# ═══════════════════════════════════════════════════════════════════════════════
# SSH BUILD CLIENT
# ═══════════════════════════════════════════════════════════════════════════════

class SSHBuildClient:
    """SSH client for remote Xcode builds"""
    
    def __init__(self, config: ConfigManager):
        self.config = config
        self.client: Optional[paramiko.SSHClient] = None
        self.connected = False
        self.last_log = []
        
    def connect(self) -> bool:
        """Establish SSH connection to the Mac"""
        try:
            self.client = paramiko.SSHClient()
            self.client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            
            host = self.config.get("ssh", "host")
            port = self.config.get("ssh", "port")
            username = self.config.get("ssh", "username")
            password = self.config.get("ssh", "password")
            key_path = self.config.get("ssh", "key_path")
            
            print(f"\n{Colors.CYAN}🔗 Connecting to {host}:{port}...{Colors.ENDC}")
            
            if key_path and os.path.exists(key_path):
                key = paramiko.RSAKey.from_private_key_file(key_path)
                self.client.connect(hostname=host, port=port, username=username, pkey=key)
            else:
                self.client.connect(hostname=host, port=port, username=username, password=password)
            
            self.connected = True
            print(f"{Colors.GREEN}✅ Connected successfully!{Colors.ENDC}")
            return True
            
        except paramiko.AuthenticationException:
            print(f"{Colors.RED}❌ Authentication failed. Check credentials.{Colors.ENDC}")
            return False
        except Exception as e:
            print(f"{Colors.RED}❌ Connection failed: {e}{Colors.ENDC}")
            return False
    
    def execute(self, command: str, show_output: bool = True) -> tuple[int, str]:
        """Execute a command on the remote Mac"""
        if not self.client:
            raise Exception("Not connected")
        
        self.last_log.append(f"$ {command}")
        stdin, stdout, stderr = self.client.exec_command(command, get_pty=True)
        
        output_lines = []
        for line in iter(stdout.readline, ''):
            if show_output:
                print(f"  {Colors.GRAY}{line}{Colors.ENDC}", end='')
            output_lines.append(line.strip())
            self.last_log.append(line.strip())
        
        exit_code = stdout.channel.recv_exit_status()
        return exit_code, '\n'.join(output_lines)
    
    def clone_repo(self) -> bool:
        """Clone the Git repository"""
        repo_url = self.config.get("build", "repo_url")
        branch = self.config.get("build", "branch")
        target_dir = self.config.get("build", "target_dir")
        
        print(f"\n{Colors.HEADER}📦 CLONING REPOSITORY{Colors.ENDC}")
        print(f"   {Colors.GRAY}Repository:{Colors.ENDC} {repo_url}")
        print(f"   {Colors.GRAY}Branch:{Colors.ENDC} {branch}")
        print(f"   {Colors.GRAY}Target:{Colors.ENDC} {target_dir}")
        print()
        
        self.execute(f"rm -rf {target_dir}", show_output=False)
        exit_code, _ = self.execute(f"git clone --recursive --branch {branch} {repo_url} {target_dir}")
        
        if exit_code == 0:
            print(f"\n{Colors.GREEN}✅ Repository cloned successfully!{Colors.ENDC}")
            return True
        else:
            print(f"\n{Colors.RED}❌ Clone failed!{Colors.ENDC}")
            return False
    
    def build(self) -> bool:
        """Build the project with Xcode using codemagic.yaml commands"""
        target_dir = self.config.get("build", "target_dir")
        project_name = self.config.get("build", "project_name")
        
        print(f"\n{Colors.HEADER}🔨 BUILDING PROJECT (Codemagic Style){Colors.ENDC}")
        print(f"   {Colors.GRAY}Running exact commands from codemagic.yaml{Colors.ENDC}")
        print()
        
        # Step 1: Initialize submodules
        print(f"{Colors.CYAN}� Step 1/4: Initializing submodules...{Colors.ENDC}")
        self.execute(f"cd {target_dir} && git submodule update --init --recursive")
        
        # Step 2: Download dependencies
        print(f"\n{Colors.CYAN}📥 Step 2/4: Downloading dependencies...{Colors.ENDC}")
        self.execute(f"cd {target_dir} && make deps || true")
        
        # Step 3: Build iOS Archive
        print(f"\n{Colors.CYAN}🏗️ Step 3/4: Building iOS Archive...{Colors.ENDC}")
        build_cmd = f"cd {target_dir} && xcodebuild -project {project_name}.xcodeproj -scheme {project_name} -configuration Release -sdk iphoneos -destination generic/platform=iOS -archivePath build/{project_name}.xcarchive -skipPackagePluginValidation -skipMacroValidation archive CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= DEVELOPMENT_TEAM="
        exit_code, _ = self.execute(build_cmd)
        
        # Step 4: Create unsigned IPA (exact codemagic command)
        print(f"\n{Colors.CYAN}📱 Step 4/4: Creating unsigned IPA...{Colors.ENDC}")
        ipa_cmd = f"""cd {target_dir} && \\
            mkdir -p packages && \\
            cd build/{project_name}.xcarchive/Products/Applications && \\
            mkdir -p Payload && \\
            cp -r {project_name}.app Payload/ && \\
            zip -r ../../../../packages/{project_name}.ipa Payload"""
        self.execute(ipa_cmd)
        
        # Check for IPA
        check_code, output = self.execute(f"ls -la {target_dir}/packages/*.ipa 2>/dev/null", show_output=False)
        
        if f"{project_name}.ipa" in output:
            print(f"\n{Colors.GREEN}✅ Build successful! IPA created.{Colors.ENDC}")
            return True
        else:
            print(f"\n{Colors.RED}❌ Build failed or IPA not created.{Colors.ENDC}")
            return False
    
    def download_ipa(self) -> Optional[str]:
        """Download the built IPA"""
        target_dir = self.config.get("build", "target_dir")
        project_name = self.config.get("build", "project_name")
        local_dir = self.config.get("output", "local_dir")
        
        remote_path = f"{target_dir}/packages/{project_name}.ipa"
        # Expand ~ in remote path
        remote_path = remote_path.replace("~", f"/Users/{self.config.get('ssh', 'username')}")
        local_path = os.path.join(local_dir, f"{project_name}.ipa")
        
        print(f"\n{Colors.HEADER}📥 DOWNLOADING IPA{Colors.ENDC}")
        
        try:
            os.makedirs(local_dir, exist_ok=True)
            sftp = self.client.open_sftp()
            sftp.get(remote_path, local_path)
            sftp.close()
            
            file_size = os.path.getsize(local_path)
            print(f"{Colors.GREEN}✅ Downloaded: {local_path} ({file_size / 1024 / 1024:.2f} MB){Colors.ENDC}")
            return os.path.abspath(local_path)
            
        except Exception as e:
            print(f"{Colors.RED}❌ Download failed: {e}{Colors.ENDC}")
            return None
    
    def disconnect(self):
        """Close SSH connection"""
        if self.client:
            self.client.close()
            self.connected = False
            print(f"\n{Colors.CYAN}🔌 Disconnected.{Colors.ENDC}")


# ═══════════════════════════════════════════════════════════════════════════════
# WEB SERVER
# ═══════════════════════════════════════════════════════════════════════════════

class IPAHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP handler for serving IPA files"""
    
    ipa_path = None
    
    def do_GET(self):
        if self.path == "/download" or self.path.endswith(".ipa"):
            self.serve_ipa()
        elif self.path == "/status":
            self.serve_status()
        else:
            self.serve_page()
    
    def serve_ipa(self):
        if not IPAHandler.ipa_path or not os.path.exists(IPAHandler.ipa_path):
            self.send_error(404, "IPA not found")
            return
        
        file_size = os.path.getsize(IPAHandler.ipa_path)
        file_name = os.path.basename(IPAHandler.ipa_path)
        
        self.send_response(200)
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Content-Disposition", f'attachment; filename="{file_name}"')
        self.send_header("Content-Length", str(file_size))
        self.end_headers()
        
        with open(IPAHandler.ipa_path, "rb") as f:
            self.wfile.write(f.read())
        
        print(f"{Colors.GREEN}📤 IPA downloaded by {self.client_address[0]}{Colors.ENDC}")
    
    def serve_status(self):
        status = {
            "status": "ready" if IPAHandler.ipa_path else "no_build",
            "ipa_available": os.path.exists(IPAHandler.ipa_path) if IPAHandler.ipa_path else False,
            "timestamp": datetime.now().isoformat()
        }
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(status).encode())
    
    def serve_page(self):
        ipa_exists = IPAHandler.ipa_path and os.path.exists(IPAHandler.ipa_path)
        ipa_name = os.path.basename(IPAHandler.ipa_path) if IPAHandler.ipa_path else "N/A"
        ipa_size = f"{os.path.getsize(IPAHandler.ipa_path) / 1024 / 1024:.2f} MB" if ipa_exists else "N/A"
        
        html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EthSign Build Server</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0a0a1a 0%, #1a1a3e 50%, #0a2a4a 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            color: white;
        }}
        .card {{
            text-align: center;
            padding: 3rem;
            background: rgba(255,255,255,0.05);
            border-radius: 24px;
            backdrop-filter: blur(20px);
            border: 1px solid rgba(255,255,255,0.1);
            box-shadow: 0 25px 50px -12px rgba(0,0,0,0.5);
            max-width: 450px;
            width: 90%;
        }}
        .logo {{ font-size: 4rem; margin-bottom: 1rem; }}
        h1 {{
            font-size: 1.8rem;
            margin-bottom: 0.5rem;
            background: linear-gradient(90deg, #00d4aa, #7c3aed, #f472b6);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }}
        .sub {{ color: rgba(255,255,255,0.5); margin-bottom: 2rem; }}
        .info {{
            background: rgba(0,0,0,0.3);
            padding: 1.5rem;
            border-radius: 16px;
            margin-bottom: 2rem;
            text-align: left;
        }}
        .row {{
            display: flex;
            justify-content: space-between;
            padding: 0.6rem 0;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }}
        .row:last-child {{ border: none; }}
        .label {{ color: rgba(255,255,255,0.5); }}
        .value {{ font-weight: 600; }}
        .btn {{
            display: inline-block;
            padding: 1rem 3rem;
            font-size: 1rem;
            font-weight: 600;
            color: white;
            background: linear-gradient(135deg, #00d4aa, #00b894);
            border: none;
            border-radius: 50px;
            cursor: pointer;
            text-decoration: none;
            transition: all 0.3s ease;
            box-shadow: 0 10px 30px -10px rgba(0,212,170,0.4);
        }}
        .btn:hover {{ transform: translateY(-3px); }}
        .btn.disabled {{ background: #444; pointer-events: none; }}
        .status {{
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.5rem 1rem;
            background: {"rgba(0,212,170,0.2)" if ipa_exists else "rgba(255,82,82,0.2)"};
            border-radius: 20px;
            margin-bottom: 1rem;
            font-size: 0.9rem;
        }}
        .dot {{
            width: 8px; height: 8px;
            border-radius: 50%;
            background: {"#00d4aa" if ipa_exists else "#ff5252"};
            animation: pulse 2s infinite;
        }}
        @keyframes pulse {{ 0%,100%{{opacity:1}} 50%{{opacity:0.5}} }}
    </style>
</head>
<body>
    <div class="card">
        <div class="logo">📱</div>
        <h1>EthSign Build Server</h1>
        <p class="sub">Xcode Remote Build System</p>
        <div class="status">
            <span class="dot"></span>
            <span>{"Build Ready" if ipa_exists else "No Build"}</span>
        </div>
        <div class="info">
            <div class="row"><span class="label">File</span><span class="value">{ipa_name}</span></div>
            <div class="row"><span class="label">Size</span><span class="value">{ipa_size}</span></div>
            <div class="row"><span class="label">Status</span><span class="value">{"✅ Ready" if ipa_exists else "⏳ Waiting"}</span></div>
        </div>
        <a href="/download" class="btn {"" if ipa_exists else "disabled"}">⬇️ Download IPA</a>
    </div>
</body>
</html>"""
        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.end_headers()
        self.wfile.write(html.encode())
    
    def log_message(self, *args):
        pass


class BuildServer:
    """HTTP server for serving IPA files"""
    
    def __init__(self, port: int):
        self.port = port
        self.server = None
        self.thread = None
        self.running = False
    
    def start(self, ipa_path: str = None):
        IPAHandler.ipa_path = ipa_path
        self.server = socketserver.TCPServer(("", self.port), IPAHandler)
        self.thread = threading.Thread(target=self.server.serve_forever)
        self.thread.daemon = True
        self.thread.start()
        self.running = True
    
    def stop(self):
        if self.server:
            self.server.shutdown()
            self.running = False


# ═══════════════════════════════════════════════════════════════════════════════
# MAIN APPLICATION
# ═══════════════════════════════════════════════════════════════════════════════

class Application:
    """Main application class"""
    
    def __init__(self):
        self.config = ConfigManager()
        self.ssh_client = SSHBuildClient(self.config)
        self.server = BuildServer(self.config.get("server", "port"))
        self.ipa_path: Optional[str] = None
    
    def run(self):
        """Main application loop"""
        while True:
            self.show_main_menu()
    
    def show_main_menu(self):
        """Display the main menu"""
        print_header()
        
        # Status info
        ssh_status = f"{Colors.GREEN}● Connected{Colors.ENDC}" if self.ssh_client.connected else f"{Colors.RED}● Disconnected{Colors.ENDC}"
        server_status = f"{Colors.GREEN}● Running (:{self.config.get('server', 'port')}){Colors.ENDC}" if self.server.running else f"{Colors.GRAY}● Stopped{Colors.ENDC}"
        ipa_status = f"{Colors.GREEN}● {os.path.basename(self.ipa_path)}{Colors.ENDC}" if self.ipa_path else f"{Colors.GRAY}● No build{Colors.ENDC}"
        
        # Show current Mac address if set
        mac_addr = self.config.get('ssh', 'host')
        mac_display = f"{Colors.GREEN}{mac_addr}{Colors.ENDC}" if mac_addr else f"{Colors.YELLOW}Not Set{Colors.ENDC}"
        
        print(f"""
  {Colors.GRAY}┌─ STATUS ─────────────────────────────────────────────────────┐{Colors.ENDC}
  {Colors.GRAY}│{Colors.ENDC}  Mac Address: {mac_display:<43} {Colors.GRAY}│{Colors.ENDC}
  {Colors.GRAY}│{Colors.ENDC}  SSH: {ssh_status:<35} {Colors.GRAY}│{Colors.ENDC}
  {Colors.GRAY}│{Colors.ENDC}  Server: {server_status:<32} {Colors.GRAY}│{Colors.ENDC}
  {Colors.GRAY}│{Colors.ENDC}  IPA: {ipa_status:<35} {Colors.GRAY}│{Colors.ENDC}
  {Colors.GRAY}└───────────────────────────────────────────────────────────────┘{Colors.ENDC}

  {Colors.WHITE}{Colors.BOLD}MAIN MENU{Colors.ENDC}
  
  {Colors.GREEN}[Q]{Colors.ENDC} ⚡ Quick Setup (Enter Mac Address)
  
  {Colors.CYAN}[1]{Colors.ENDC} 🚀 Start Full Build Process
  {Colors.CYAN}[2]{Colors.ENDC} ⚙️  Configuration
  {Colors.CYAN}[3]{Colors.ENDC} 🔗 SSH Connection
  {Colors.CYAN}[4]{Colors.ENDC} 🌐 Web Server
  {Colors.CYAN}[5]{Colors.ENDC} 📁 Select Existing IPA
  {Colors.CYAN}[6]{Colors.ENDC} 📋 View Build Logs
  {Colors.CYAN}[7]{Colors.ENDC} 🔍 Find Mac on Network
  {Colors.CYAN}[8]{Colors.ENDC} 📖 Mac Setup Guide
  {Colors.CYAN}[9]{Colors.ENDC} ❓ Help
  
  {Colors.RED}[0]{Colors.ENDC} Exit
        """)
        
        choice = input(f"\n  {Colors.YELLOW}Enter choice:{Colors.ENDC} ").strip().lower()
        
        if choice == "q":
            self.quick_setup()
        elif choice == "1":
            self.start_build_process()
        elif choice == "2":
            self.show_config_menu()
        elif choice == "3":
            self.show_ssh_menu()
        elif choice == "4":
            self.show_server_menu()
        elif choice == "5":
            self.select_ipa()
        elif choice == "6":
            self.view_logs()
        elif choice == "7":
            self.scan_network()
        elif choice == "8":
            self.show_mac_setup_guide()
        elif choice == "9":
            self.show_help()
        elif choice == "0":
            self.exit_app()
    
    def quick_setup(self):
        """Quick setup to enter Mac address and credentials"""
        print_header()
        print(f"""
  {Colors.WHITE}{Colors.BOLD}⚡ QUICK SETUP{Colors.ENDC}
  
  {Colors.GRAY}Enter your Mac/Hackintosh connection details:{Colors.ENDC}
        """)
        
        # Current values
        current_host = self.config.get('ssh', 'host') or "(not set)"
        current_user = self.config.get('ssh', 'username') or "(not set)"
        
        print(f"  {Colors.GRAY}Current Host: {current_host}{Colors.ENDC}")
        print(f"  {Colors.GRAY}Current User: {current_user}{Colors.ENDC}")
        print()
        
        # Get Mac address
        host = input(f"  {Colors.CYAN}Mac IP Address{Colors.ENDC} (e.g., 192.168.1.100): ").strip()
        if host:
            self.config.set(host, "ssh", "host")
        
        # Get username
        username = input(f"  {Colors.CYAN}Mac Username{Colors.ENDC} (your Mac login name): ").strip()
        if username:
            self.config.set(username, "ssh", "username")
        
        # Get password
        password = input(f"  {Colors.CYAN}Mac Password{Colors.ENDC} (leave blank to skip): ").strip()
        if password:
            self.config.set(password, "ssh", "password")
        
        # Save
        if host or username:
            self.config.save()
            print(f"\n  {Colors.GREEN}✅ Settings saved!{Colors.ENDC}")
            
            # Offer to test connection
            test = input(f"\n  {Colors.YELLOW}Test connection now? (y/n):{Colors.ENDC} ").strip().lower()
            if test == 'y':
                if self.ssh_client.connect():
                    print(f"\n  {Colors.GREEN}✅ Connection successful!{Colors.ENDC}")
                    self.ssh_client.disconnect()
        
        input(f"\n  {Colors.GRAY}Press Enter to continue...{Colors.ENDC}")
    
    def start_build_process(self):
        """Start the full build process"""
        print_header()
        print(f"\n  {Colors.WHITE}{Colors.BOLD}🚀 STARTING FULL BUILD PROCESS{Colors.ENDC}\n")
        
        # Check config
        if not self.config.get("ssh", "host"):
            print(f"  {Colors.RED}❌ SSH not configured! Go to Configuration first.{Colors.ENDC}")
            input(f"\n  {Colors.GRAY}Press Enter to continue...{Colors.ENDC}")
            return
        
        print(f"  {Colors.GRAY}This will:{Colors.ENDC}")
        print(f"  1. Connect to {self.config.get('ssh', 'host')} via SSH")
        print(f"  2. Clone {self.config.get('build', 'repo_url')}")
        print(f"  3. Build with Xcode")
        print(f"  4. Download the IPA")
        print(f"  5. Start web server on port {self.config.get('server', 'port')}")
        
        confirm = input(f"\n  {Colors.YELLOW}Proceed? (y/n):{Colors.ENDC} ").strip().lower()
        if confirm != 'y':
            return
        
        print()
        
        # Step 1: Connect
        if not self.ssh_client.connected:
            if not self.ssh_client.connect():
                input(f"\n  {Colors.GRAY}Press Enter to continue...{Colors.ENDC}")
                return
        
        # Step 2: Clone
        if not self.ssh_client.clone_repo():
            input(f"\n  {Colors.GRAY}Press Enter to continue...{Colors.ENDC}")
            return
        
        # Step 3: Build
        if not self.ssh_client.build():
            input(f"\n  {Colors.GRAY}Press Enter to continue...{Colors.ENDC}")
            return
        
        # Step 4: Download
        self.ipa_path = self.ssh_client.download_ipa()
        if not self.ipa_path:
            input(f"\n  {Colors.GRAY}Press Enter to continue...{Colors.ENDC}")
            return
        
        # Step 5: Start server
        if not self.server.running:
            self.server = BuildServer(self.config.get("server", "port"))
            self.server.start(self.ipa_path)
        else:
            IPAHandler.ipa_path = self.ipa_path
        
        print(f"""
{Colors.GREEN}{'═' * 60}
  ✅ BUILD COMPLETE!
{'═' * 60}{Colors.ENDC}

  📍 Web Server: {Colors.CYAN}http://localhost:{self.config.get('server', 'port')}{Colors.ENDC}
  📥 Download:   {Colors.CYAN}http://localhost:{self.config.get('server', 'port')}/download{Colors.ENDC}
  📁 Local File: {Colors.CYAN}{self.ipa_path}{Colors.ENDC}
        """)
        
        input(f"\n  {Colors.GRAY}Press Enter to return to menu...{Colors.ENDC}")
    
    def show_config_menu(self):
        """Show configuration menu"""
        while True:
            print_header()
            print(f"""
  {Colors.WHITE}{Colors.BOLD}⚙️  CONFIGURATION{Colors.ENDC}
  
  {Colors.GRAY}── SSH Settings ──{Colors.ENDC}
  {Colors.CYAN}[1]{Colors.ENDC} Host:     {Colors.WHITE}{self.config.get('ssh', 'host') or '(not set)'}{Colors.ENDC}
  {Colors.CYAN}[2]{Colors.ENDC} Port:     {Colors.WHITE}{self.config.get('ssh', 'port')}{Colors.ENDC}
  {Colors.CYAN}[3]{Colors.ENDC} Username: {Colors.WHITE}{self.config.get('ssh', 'username') or '(not set)'}{Colors.ENDC}
  {Colors.CYAN}[4]{Colors.ENDC} Password: {Colors.WHITE}{'●●●●●●●●' if self.config.get('ssh', 'password') else '(not set)'}{Colors.ENDC}
  {Colors.CYAN}[5]{Colors.ENDC} SSH Key:  {Colors.WHITE}{self.config.get('ssh', 'key_path') or '(not set)'}{Colors.ENDC}
  
  {Colors.GRAY}── Build Settings ──{Colors.ENDC}
  {Colors.CYAN}[6]{Colors.ENDC} Repository: {Colors.WHITE}{self.config.get('build', 'repo_url')}{Colors.ENDC}
  {Colors.CYAN}[7]{Colors.ENDC} Branch:     {Colors.WHITE}{self.config.get('build', 'branch')}{Colors.ENDC}
  {Colors.CYAN}[8]{Colors.ENDC} Target Dir: {Colors.WHITE}{self.config.get('build', 'target_dir')}{Colors.ENDC}
  {Colors.CYAN}[9]{Colors.ENDC} Project:    {Colors.WHITE}{self.config.get('build', 'project_name')}{Colors.ENDC}
  
  {Colors.GRAY}── Server Settings ──{Colors.ENDC}
  {Colors.CYAN}[10]{Colors.ENDC} Server Port: {Colors.WHITE}{self.config.get('server', 'port')}{Colors.ENDC}
  
  {Colors.GREEN}[S]{Colors.ENDC} Save Configuration
  {Colors.RED}[0]{Colors.ENDC} Back to Main Menu
            """)
            
            choice = input(f"\n  {Colors.YELLOW}Enter choice:{Colors.ENDC} ").strip().lower()
            
            if choice == "1":
                val = input(f"  Enter SSH Host: ").strip()
                if val: self.config.set(val, "ssh", "host")
            elif choice == "2":
                val = input(f"  Enter SSH Port: ").strip()
                if val.isdigit(): self.config.set(int(val), "ssh", "port")
            elif choice == "3":
                val = input(f"  Enter Username: ").strip()
                if val: self.config.set(val, "ssh", "username")
            elif choice == "4":
                val = input(f"  Enter Password: ").strip()
                if val: self.config.set(val, "ssh", "password")
            elif choice == "5":
                val = input(f"  Enter SSH Key Path: ").strip()
                self.config.set(val, "ssh", "key_path")
            elif choice == "6":
                val = input(f"  Enter Repository URL: ").strip()
                if val: self.config.set(val, "build", "repo_url")
            elif choice == "7":
                val = input(f"  Enter Branch: ").strip()
                if val: self.config.set(val, "build", "branch")
            elif choice == "8":
                val = input(f"  Enter Target Directory: ").strip()
                if val: self.config.set(val, "build", "target_dir")
            elif choice == "9":
                val = input(f"  Enter Project Name: ").strip()
                if val: self.config.set(val, "build", "project_name")
            elif choice == "10":
                val = input(f"  Enter Server Port: ").strip()
                if val.isdigit(): self.config.set(int(val), "server", "port")
            elif choice == "s":
                self.config.save()
                time.sleep(1)
            elif choice == "0":
                return
    
    def show_ssh_menu(self):
        """Show SSH connection menu"""
        while True:
            print_header()
            status = f"{Colors.GREEN}● Connected to {self.config.get('ssh', 'host')}{Colors.ENDC}" if self.ssh_client.connected else f"{Colors.RED}● Disconnected{Colors.ENDC}"
            
            print(f"""
  {Colors.WHITE}{Colors.BOLD}🔗 SSH CONNECTION{Colors.ENDC}
  
  Status: {status}
  
  {Colors.CYAN}[1]{Colors.ENDC} Connect
  {Colors.CYAN}[2]{Colors.ENDC} Disconnect
  {Colors.CYAN}[3]{Colors.ENDC} Test Connection
  {Colors.CYAN}[4]{Colors.ENDC} Run Custom Command
  
  {Colors.RED}[0]{Colors.ENDC} Back
            """)
            
            choice = input(f"\n  {Colors.YELLOW}Enter choice:{Colors.ENDC} ").strip()
            
            if choice == "1":
                self.ssh_client.connect()
                input(f"\n  {Colors.GRAY}Press Enter...{Colors.ENDC}")
            elif choice == "2":
                self.ssh_client.disconnect()
                input(f"\n  {Colors.GRAY}Press Enter...{Colors.ENDC}")
            elif choice == "3":
                if self.ssh_client.connected:
                    print("\n  Testing connection...")
                    exit_code, output = self.ssh_client.execute("echo 'Connection OK' && uname -a", show_output=False)
                    print(f"  {Colors.GREEN}✅ {output}{Colors.ENDC}")
                else:
                    print(f"  {Colors.RED}Not connected!{Colors.ENDC}")
                input(f"\n  {Colors.GRAY}Press Enter...{Colors.ENDC}")
            elif choice == "4":
                if self.ssh_client.connected:
                    cmd = input("  Enter command: ").strip()
                    if cmd:
                        print()
                        self.ssh_client.execute(cmd)
                else:
                    print(f"  {Colors.RED}Not connected!{Colors.ENDC}")
                input(f"\n  {Colors.GRAY}Press Enter...{Colors.ENDC}")
            elif choice == "0":
                return
    
    def show_server_menu(self):
        """Show web server menu"""
        while True:
            print_header()
            status = f"{Colors.GREEN}● Running on port {self.config.get('server', 'port')}{Colors.ENDC}" if self.server.running else f"{Colors.RED}● Stopped{Colors.ENDC}"
            
            print(f"""
  {Colors.WHITE}{Colors.BOLD}🌐 WEB SERVER{Colors.ENDC}
  
  Status: {status}
  IPA: {self.ipa_path or '(none selected)'}
  
  {Colors.CYAN}[1]{Colors.ENDC} Start Server
  {Colors.CYAN}[2]{Colors.ENDC} Stop Server
  {Colors.CYAN}[3]{Colors.ENDC} Open in Browser
  {Colors.CYAN}[4]{Colors.ENDC} Change Port
  
  {Colors.RED}[0]{Colors.ENDC} Back
            """)
            
            choice = input(f"\n  {Colors.YELLOW}Enter choice:{Colors.ENDC} ").strip()
            
            if choice == "1":
                if self.server.running:
                    print(f"  {Colors.YELLOW}Server already running!{Colors.ENDC}")
                else:
                    self.server = BuildServer(self.config.get("server", "port"))
                    self.server.start(self.ipa_path)
                    print(f"  {Colors.GREEN}✅ Server started on http://localhost:{self.config.get('server', 'port')}{Colors.ENDC}")
                input(f"\n  {Colors.GRAY}Press Enter...{Colors.ENDC}")
            elif choice == "2":
                if self.server.running:
                    self.server.stop()
                    print(f"  {Colors.GREEN}✅ Server stopped{Colors.ENDC}")
                else:
                    print(f"  {Colors.YELLOW}Server not running{Colors.ENDC}")
                input(f"\n  {Colors.GRAY}Press Enter...{Colors.ENDC}")
            elif choice == "3":
                if self.server.running:
                    import webbrowser
                    webbrowser.open(f"http://localhost:{self.config.get('server', 'port')}")
                else:
                    print(f"  {Colors.RED}Server not running!{Colors.ENDC}")
                    input(f"\n  {Colors.GRAY}Press Enter...{Colors.ENDC}")
            elif choice == "4":
                val = input("  Enter new port: ").strip()
                if val.isdigit():
                    self.config.set(int(val), "server", "port")
                    self.config.save()
                input(f"\n  {Colors.GRAY}Press Enter...{Colors.ENDC}")
            elif choice == "0":
                return
    
    def select_ipa(self):
        """Select an existing IPA file"""
        print_header()
        print(f"\n  {Colors.WHITE}{Colors.BOLD}📁 SELECT IPA FILE{Colors.ENDC}\n")
        
        # List IPAs in build_output
        output_dir = self.config.get("output", "local_dir")
        if os.path.exists(output_dir):
            ipas = [f for f in os.listdir(output_dir) if f.endswith('.ipa')]
            if ipas:
                print(f"  {Colors.GRAY}Found in {output_dir}:{Colors.ENDC}")
                for i, ipa in enumerate(ipas, 1):
                    size = os.path.getsize(os.path.join(output_dir, ipa)) / 1024 / 1024
                    print(f"  {Colors.CYAN}[{i}]{Colors.ENDC} {ipa} ({size:.2f} MB)")
        
        print(f"\n  {Colors.CYAN}[C]{Colors.ENDC} Enter custom path")
        print(f"  {Colors.RED}[0]{Colors.ENDC} Cancel")
        
        choice = input(f"\n  {Colors.YELLOW}Enter choice:{Colors.ENDC} ").strip().lower()
        
        if choice == "c":
            path = input("  Enter IPA path: ").strip()
            if os.path.exists(path) and path.endswith('.ipa'):
                self.ipa_path = os.path.abspath(path)
                print(f"  {Colors.GREEN}✅ Selected: {self.ipa_path}{Colors.ENDC}")
            else:
                print(f"  {Colors.RED}Invalid path!{Colors.ENDC}")
        elif choice.isdigit() and int(choice) > 0:
            idx = int(choice) - 1
            if idx < len(ipas):
                self.ipa_path = os.path.abspath(os.path.join(output_dir, ipas[idx]))
                print(f"  {Colors.GREEN}✅ Selected: {self.ipa_path}{Colors.ENDC}")
                
                # Update server if running
                if self.server.running:
                    IPAHandler.ipa_path = self.ipa_path
        
        input(f"\n  {Colors.GRAY}Press Enter...{Colors.ENDC}")
    
    def view_logs(self):
        """View build logs"""
        print_header()
        print(f"\n  {Colors.WHITE}{Colors.BOLD}📋 BUILD LOGS{Colors.ENDC}\n")
        
        if self.ssh_client.last_log:
            for line in self.ssh_client.last_log[-50:]:  # Last 50 lines
                print(f"  {Colors.GRAY}{line}{Colors.ENDC}")
        else:
            print(f"  {Colors.GRAY}No logs available yet.{Colors.ENDC}")
        
        input(f"\n  {Colors.GRAY}Press Enter...{Colors.ENDC}")
    
    def scan_network(self):
        """Scan the network for Mac/SSH devices"""
        print_header()
        print(f"\n  {Colors.WHITE}{Colors.BOLD}🔍 NETWORK SCANNER{Colors.ENDC}")
        print(f"\n  {Colors.GRAY}This will scan your local network for devices with SSH enabled.{Colors.ENDC}")
        print(f"  {Colors.GRAY}Mac/Hackintosh devices with Remote Login enabled will be found.{Colors.ENDC}")
        
        # Get local IP to determine subnet
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            local_ip = s.getsockname()[0]
            s.close()
            subnet = '.'.join(local_ip.split('.')[:-1])
        except:
            subnet = "192.168.1"
            local_ip = "Unknown"
        
        print(f"\n  {Colors.CYAN}Your IP:{Colors.ENDC} {local_ip}")
        print(f"  {Colors.CYAN}Scanning:{Colors.ENDC} {subnet}.1-254")
        
        custom = input(f"\n  {Colors.YELLOW}Press Enter to scan, or type a different subnet (e.g., 192.168.0):{Colors.ENDC} ").strip()
        if custom:
            subnet = custom
        
        print(f"\n  {Colors.CYAN}Scanning for SSH devices...{Colors.ENDC}")
        print(f"  {Colors.GRAY}(This may take 30-60 seconds){Colors.ENDC}\n")
        
        def check_ssh(ip: str) -> Tuple[str, bool, str]:
            """Check if IP has SSH port open and try to identify it"""
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(1)
                result = sock.connect_ex((ip, 22))
                sock.close()
                
                if result == 0:
                    # Try to get SSH banner
                    try:
                        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                        sock.settimeout(2)
                        sock.connect((ip, 22))
                        banner = sock.recv(256).decode('utf-8', errors='ignore').strip()
                        sock.close()
                        return (ip, True, banner)
                    except:
                        return (ip, True, "SSH")
                return (ip, False, "")
            except:
                return (ip, False, "")
        
        # Scan in parallel
        found_devices: List[Tuple[str, str]] = []
        with concurrent.futures.ThreadPoolExecutor(max_workers=50) as executor:
            ips = [f"{subnet}.{i}" for i in range(1, 255)]
            futures = {executor.submit(check_ssh, ip): ip for ip in ips}
            
            done_count = 0
            for future in concurrent.futures.as_completed(futures):
                done_count += 1
                if done_count % 25 == 0:
                    print(f"  {Colors.GRAY}Scanned {done_count}/254...{Colors.ENDC}")
                
                ip, has_ssh, banner = future.result()
                if has_ssh:
                    found_devices.append((ip, banner))
                    print(f"  {Colors.GREEN}✅ Found: {ip} - {banner[:50]}{Colors.ENDC}")
        
        print(f"\n  {Colors.WHITE}{'═' * 50}{Colors.ENDC}")
        print(f"  {Colors.WHITE}{Colors.BOLD}SCAN COMPLETE{Colors.ENDC}")
        print(f"  {Colors.WHITE}{'═' * 50}{Colors.ENDC}")
        
        if found_devices:
            print(f"\n  {Colors.GREEN}Found {len(found_devices)} device(s) with SSH:{Colors.ENDC}\n")
            for i, (ip, banner) in enumerate(found_devices, 1):
                is_mac = "OpenSSH" in banner or "macOS" in banner.lower()
                icon = "🍎" if is_mac else "💻"
                print(f"  {Colors.CYAN}[{i}]{Colors.ENDC} {icon} {ip}")
                print(f"      {Colors.GRAY}{banner[:60]}{Colors.ENDC}")
            
            print()
            choice = input(f"  {Colors.YELLOW}Enter number to use that IP (or 0 to cancel):{Colors.ENDC} ").strip()
            if choice.isdigit() and 0 < int(choice) <= len(found_devices):
                selected_ip = found_devices[int(choice) - 1][0]
                self.config.set(selected_ip, "ssh", "host")
                print(f"\n  {Colors.GREEN}✅ Set SSH host to: {selected_ip}{Colors.ENDC}")
                self.config.save()
        else:
            print(f"\n  {Colors.YELLOW}No SSH devices found on {subnet}.x{Colors.ENDC}")
            print(f"\n  {Colors.GRAY}Make sure:{Colors.ENDC}")
            print(f"  • Your Mac/Hackintosh is on the same network")
            print(f"  • Remote Login is enabled (see Mac Setup Guide)")
            print(f"  • Firewall is not blocking port 22")
        
        input(f"\n  {Colors.GRAY}Press Enter...{Colors.ENDC}")
    
    def show_mac_setup_guide(self):
        """Show Mac/Hackintosh SSH setup guide"""
        print_header()
        print(f"""
  {Colors.WHITE}{Colors.BOLD}📖 MAC/HACKINTOSH SSH SETUP GUIDE{Colors.ENDC}
  
  {Colors.CYAN}{'═' * 55}{Colors.ENDC}
  
  {Colors.WHITE}STEP 1: Enable Remote Login (SSH){Colors.ENDC}
  
  {Colors.GRAY}On your Mac or Hackintosh:{Colors.ENDC}
  
  1. Open {Colors.CYAN}System Preferences{Colors.ENDC} (or System Settings on Ventura+)
  2. Go to {Colors.CYAN}Sharing{Colors.ENDC} (or General → Sharing)
  3. Turn ON {Colors.GREEN}Remote Login{Colors.ENDC}
  4. Set "Allow access for" to {Colors.CYAN}All users{Colors.ENDC}
  
  {Colors.CYAN}{'─' * 55}{Colors.ENDC}
  
  {Colors.WHITE}STEP 2: Find Your Mac's IP Address{Colors.ENDC}
  
  {Colors.GRAY}Open Terminal on Mac and run:{Colors.ENDC}
  
  {Colors.CYAN}ifconfig | grep "inet " | grep -v 127.0.0.1{Colors.ENDC}
  
  {Colors.GRAY}Or check:{Colors.ENDC} System Preferences → Network → Your IP is shown
  
  {Colors.CYAN}{'─' * 55}{Colors.ENDC}
  
  {Colors.WHITE}STEP 3: Test Connection{Colors.ENDC}
  
  {Colors.GRAY}From this Windows PC, open PowerShell and run:{Colors.ENDC}
  
  {Colors.CYAN}ssh username@192.168.x.x{Colors.ENDC}
  
  {Colors.GRAY}Replace 'username' with your Mac login name.{Colors.ENDC}
  
  {Colors.CYAN}{'─' * 55}{Colors.ENDC}
  
  {Colors.WHITE}STEP 4: Verify Xcode{Colors.ENDC}
  
  {Colors.GRAY}On Mac, run:{Colors.ENDC}
  
  {Colors.CYAN}xcodebuild -version{Colors.ENDC}
  {Colors.CYAN}xcode-select --install{Colors.ENDC}  {Colors.GRAY}(if not installed){Colors.ENDC}
  
  {Colors.CYAN}{'═' * 55}{Colors.ENDC}
  
  {Colors.YELLOW}TIP:{Colors.ENDC} Use option {Colors.CYAN}[7] Find Mac on Network{Colors.ENDC} to scan for your Mac!
        """)
        input(f"\n  {Colors.GRAY}Press Enter...{Colors.ENDC}")
    
    def show_help(self):
        """Show help information"""
        print_header()
        print(f"""
  {Colors.WHITE}{Colors.BOLD}❓ HELP{Colors.ENDC}
  
  {Colors.CYAN}EthSign SSH Build Tool{Colors.ENDC}
  
  This tool allows you to:
  
  • Connect to a Mac with Xcode via SSH
  • Clone a Git repository remotely
  • Build iOS apps using Xcode
  • Download the compiled IPA
  • Serve the IPA via a web server
  
  {Colors.WHITE}Quick Start:{Colors.ENDC}
  
  1. Go to {Colors.CYAN}Configuration{Colors.ENDC} and set up SSH details
  2. Set the repository URL you want to build
  3. Run {Colors.CYAN}Start Full Build Process{Colors.ENDC}
  4. Access the IPA at {Colors.CYAN}http://localhost:8080{Colors.ENDC}
  
  {Colors.WHITE}Requirements:{Colors.ENDC}
  
  • A Mac with Xcode installed
  • SSH access to the Mac
  • Python 3.9+ with paramiko
        """)
        input(f"\n  {Colors.GRAY}Press Enter...{Colors.ENDC}")
    
    def exit_app(self):
        """Exit the application"""
        if self.ssh_client.connected:
            self.ssh_client.disconnect()
        if self.server.running:
            self.server.stop()
        print(f"\n  {Colors.GREEN}Goodbye! 👋{Colors.ENDC}\n")
        sys.exit(0)


# ═══════════════════════════════════════════════════════════════════════════════
# ENTRY POINT
# ═══════════════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    try:
        app = Application()
        app.run()
    except KeyboardInterrupt:
        print(f"\n\n  {Colors.YELLOW}Interrupted. Exiting...{Colors.ENDC}\n")
        sys.exit(0)
