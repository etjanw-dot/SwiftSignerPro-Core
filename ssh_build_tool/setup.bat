@echo off
REM EthSign SSH Build Tool - Windows Batch Launcher
REM ================================================

echo.
echo  ╔═══════════════════════════════════════════════════════════╗
echo  ║          EthSign SSH Build Tool - Setup                   ║
echo  ╚═══════════════════════════════════════════════════════════╝
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is not installed or not in PATH.
    echo Please install Python 3.9+ from https://python.org
    pause
    exit /b 1
)

REM Check if venv exists, if not create it
if not exist "venv" (
    echo [*] Creating virtual environment...
    python -m venv venv
)

REM Activate virtual environment
echo [*] Activating virtual environment...
call venv\Scripts\activate.bat

REM Install requirements
echo [*] Installing dependencies...
pip install -r requirements.txt --quiet

echo.
echo [SUCCESS] Setup complete!
echo.
echo Usage examples:
echo.
echo   # Full remote build:
echo   python build_server.py --host <MAC_IP> --user <USER> --password <PASS> --repo <REPO_URL>
echo.
echo   # Serve existing IPA:
echo   python build_server.py --serve-only --ipa ..\packages\Ksign.ipa --port 8080
echo.
echo Run "python build_server.py --help" for all options.
echo.

REM Keep the command prompt open
cmd /k
