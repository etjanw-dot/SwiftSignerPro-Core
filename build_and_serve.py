#!/usr/bin/env python3
"""
Ksign Build & Serve Script
Builds the IPA and serves it on your local network for easy downloading.
"""

import subprocess
import os
import sys
import socket
import http.server
import socketserver
import threading
import time
from datetime import datetime

# Configuration
PROJECT_DIR = "/Users/ethfr/Downloads/SwiftSignerPro-Core"
IPA_NAME = "Ksign.ipa"
PORT = 8080

# Colors
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    PURPLE = '\033[95m'
    CYAN = '\033[96m'
    END = '\033[0m'
    BOLD = '\033[1m'

def print_banner():
    print(f"""
{Colors.PURPLE}{Colors.BOLD}
╔═══════════════════════════════════════════════════════════╗
║              🔨 Ksign Build & Serve Script                ║
╚═══════════════════════════════════════════════════════════╝
{Colors.END}""")

def print_step(msg):
    print(f"{Colors.CYAN}▶ {msg}{Colors.END}")

def print_success(msg):
    print(f"{Colors.GREEN}✓ {msg}{Colors.END}")

def print_error(msg):
    print(f"{Colors.RED}✗ {msg}{Colors.END}")

def print_info(msg):
    print(f"{Colors.YELLOW}ℹ {msg}{Colors.END}")

def get_local_ip():
    """Get the local IP address"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "127.0.0.1"

def build_ipa():
    """Build the Ksign IPA"""
    os.chdir(PROJECT_DIR)
    
    print_step("Building Ksign...")
    print(f"   Started: {datetime.now().strftime('%H:%M:%S')}")
    
    # Build command
    build_cmd = [
        "xcodebuild",
        "-project", "Ksign.xcodeproj",
        "-scheme", "Ksign",
        "-configuration", "Release",
        "-arch", "arm64",
        "-sdk", "iphoneos",
        "-derivedDataPath", ".build/Ksign",
        "-skipPackagePluginValidation",
        "-skipMacroValidation",
        "CODE_SIGNING_ALLOWED=NO",
        "CODE_SIGNING_REQUIRED=NO",
        "CODE_SIGN_IDENTITY=",
        "DEVELOPMENT_TEAM=",
    ]
    
    # Run build
    process = subprocess.Popen(
        build_cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True
    )
    
    errors = []
    for line in process.stdout:
        if "error:" in line.lower():
            errors.append(line.strip())
            print(f"   {Colors.RED}{line.strip()}{Colors.END}")
        elif "warning:" in line.lower() and "Ksign" in line:
            print(f"   {Colors.YELLOW}{line.strip()[:100]}{Colors.END}")
        elif "BUILD SUCCEEDED" in line or "BUILD FAILED" in line:
            print(f"   {line.strip()}")
    
    process.wait()
    
    if process.returncode != 0:
        print_error(f"Build failed with code {process.returncode}")
        if errors:
            print("\n📋 Errors:")
            for e in errors[:10]:
                print(f"   {e}")
        return False
    
    print_success("Build completed")
    return True

def create_ipa():
    """Create the IPA from the built app"""
    os.chdir(PROJECT_DIR)
    
    print_step("Creating IPA package...")
    
    app_path = ".build/Ksign/Build/Products/Release-iphoneos/Ksign.app"
    
    if not os.path.exists(app_path):
        print_error(f"App not found at: {app_path}")
        return False
    
    # Clean up
    subprocess.run(["rm", "-rf", "Payload", "packages"], capture_output=True)
    os.makedirs("Payload", exist_ok=True)
    os.makedirs("packages", exist_ok=True)
    
    # Copy app
    subprocess.run(["cp", "-r", app_path, "Payload/Ksign.app"], check=True)
    
    # Set permissions
    subprocess.run(["chmod", "-R", "0755", "Payload/Ksign.app"], check=True)
    
    # Remove code signature
    subprocess.run(["rm", "-rf", "Payload/Ksign.app/_CodeSignature"], capture_output=True)
    
    # Copy deps
    if os.path.exists("deps"):
        for f in os.listdir("deps"):
            subprocess.run(["cp", f"deps/{f}", "Payload/Ksign.app/"], capture_output=True)
    
    # Create IPA
    result = subprocess.run(
        ["zip", "-r9", f"packages/{IPA_NAME}", "Payload"],
        capture_output=True,
        text=True
    )
    
    if result.returncode != 0:
        print_error("Failed to create IPA")
        return False
    
    ipa_path = f"packages/{IPA_NAME}"
    ipa_size = os.path.getsize(ipa_path) / (1024 * 1024)
    print_success(f"IPA created: {ipa_path} ({ipa_size:.1f} MB)")
    
    return True

def serve_ipa():
    """Serve the IPA on a local HTTP server"""
    os.chdir(os.path.join(PROJECT_DIR, "packages"))
    
    local_ip = get_local_ip()
    
    # HTML page for download
    html_content = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ksign IPA Download</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'SF Pro', sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }}
        .container {{
            background: rgba(255,255,255,0.1);
            backdrop-filter: blur(20px);
            border-radius: 24px;
            padding: 40px;
            text-align: center;
            max-width: 400px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }}
        .logo {{
            width: 100px;
            height: 100px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 22px;
            margin: 0 auto 24px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 48px;
        }}
        h1 {{
            color: white;
            font-size: 28px;
            margin-bottom: 8px;
        }}
        .version {{
            color: rgba(255,255,255,0.6);
            margin-bottom: 24px;
        }}
        .download-btn {{
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-decoration: none;
            padding: 16px 40px;
            border-radius: 12px;
            font-size: 18px;
            font-weight: 600;
            transition: transform 0.2s, box-shadow 0.2s;
        }}
        .download-btn:hover {{
            transform: translateY(-2px);
            box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4);
        }}
        .info {{
            color: rgba(255,255,255,0.5);
            margin-top: 24px;
            font-size: 14px;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">📦</div>
        <h1>Ksign</h1>
        <p class="version">Custom Tweaks Edition</p>
        <a href="/{IPA_NAME}" class="download-btn">Download IPA</a>
        <p class="info">Built on {datetime.now().strftime('%Y-%m-%d %H:%M')}</p>
    </div>
</body>
</html>"""
    
    with open("index.html", "w") as f:
        f.write(html_content)
    
    # Custom handler
    class QuietHandler(http.server.SimpleHTTPRequestHandler):
        def log_message(self, format, *args):
            if ".ipa" in args[0]:
                print(f"{Colors.GREEN}📥 Download started: {args[0]}{Colors.END}")
    
    print()
    print(f"{Colors.GREEN}{Colors.BOLD}╔═══════════════════════════════════════════════════════════╗{Colors.END}")
    print(f"{Colors.GREEN}{Colors.BOLD}║                  🎉 Build Successful!                     ║{Colors.END}")
    print(f"{Colors.GREEN}{Colors.BOLD}╠═══════════════════════════════════════════════════════════╣{Colors.END}")
    print(f"{Colors.GREEN}{Colors.BOLD}║{Colors.END}  📱 Open on your iPhone:                                  {Colors.GREEN}{Colors.BOLD}║{Colors.END}")
    print(f"{Colors.GREEN}{Colors.BOLD}║{Colors.END}                                                           {Colors.GREEN}{Colors.BOLD}║{Colors.END}")
    print(f"{Colors.GREEN}{Colors.BOLD}║{Colors.END}  {Colors.CYAN}{Colors.BOLD}http://{local_ip}:{PORT}{Colors.END}                            {Colors.GREEN}{Colors.BOLD}║{Colors.END}")
    print(f"{Colors.GREEN}{Colors.BOLD}║{Colors.END}                                                           {Colors.GREEN}{Colors.BOLD}║{Colors.END}")
    print(f"{Colors.GREEN}{Colors.BOLD}║{Colors.END}  Direct download:                                        {Colors.GREEN}{Colors.BOLD}║{Colors.END}")
    print(f"{Colors.GREEN}{Colors.BOLD}║{Colors.END}  {Colors.CYAN}http://{local_ip}:{PORT}/{IPA_NAME}{Colors.END}              {Colors.GREEN}{Colors.BOLD}║{Colors.END}")
    print(f"{Colors.GREEN}{Colors.BOLD}╚═══════════════════════════════════════════════════════════╝{Colors.END}")
    print()
    print_info("Press Ctrl+C to stop the server")
    print()
    
    with socketserver.TCPServer(("", PORT), QuietHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print()
            print_info("Server stopped")

def main():
    print_banner()
    
    # Build
    if not build_ipa():
        sys.exit(1)
    
    # Create IPA
    if not create_ipa():
        sys.exit(1)
    
    # Serve
    serve_ipa()

if __name__ == "__main__":
    main()
