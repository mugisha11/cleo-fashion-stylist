@echo off
echo ========================================
echo Share Cleo Fashion Online with ngrok
echo ========================================
echo.

REM Check if Flutter is available
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter not found! Please install Flutter SDK
    pause
    exit /b 1
)

REM Check if ngrok is available
ngrok version >nul 2>&1
if errorlevel 1 (
    echo ERROR: ngrok not found!
    echo.
    echo Please install ngrok:
    echo 1. Download from: https://ngrok.com/download
    echo 2. Or use: choco install ngrok
    echo 3. Add ngrok to your PATH
    echo.
    pause
    exit /b 1
)

REM Set the port (Flutter and ngrok use the same port)
set PORT=8080
echo Using port: %PORT%
echo.

REM Kill any existing ngrok processes
taskkill /F /IM ngrok.exe >nul 2>&1

REM Start ngrok in a new window
echo Starting ngrok tunnel on port %PORT%...
start "ngrok" cmd /k ngrok http %PORT%
timeout /t 3 /nobreak >nul

echo.
echo ========================================
echo ngrok is running!
echo ========================================
echo.
echo Check the ngrok window for your public URL
echo Or visit: http://localhost:4040
echo.
echo Starting Flutter web server on port %PORT%...
echo Press Ctrl+C to stop
echo.

REM Start Flutter web server
flutter run -d web-server --web-port=%PORT%

echo.
echo Stopping ngrok...
taskkill /F /IM ngrok.exe >nul 2>&1
echo Done!
