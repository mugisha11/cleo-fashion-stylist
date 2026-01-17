@echo off
echo ========================================
echo Starting Cleo Fashion App - Fast Mode
echo ========================================
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found! Please install Python 3.13+
    pause
    exit /b 1
)

REM Check if Flutter is available
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter not found! Please install Flutter SDK
    pause
    exit /b 1
)

echo [1/3] Starting Main VTON Backend (port 8000)...
start "VTON Backend" cmd /k "cd backend && python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
timeout /t 3 /nobreak >nul

echo [2/3] Starting Secondary API Server (port 8001)...
start "API Server" cmd /k "cd server && python -m uvicorn api.main:app --host 0.0.0.0 --port 8001 --reload"
timeout /t 3 /nobreak >nul

echo [3/3] Starting Flutter Frontend (dev mode, HTML renderer)...
start "Flutter Frontend" cmd /k "flutter run -d chrome --web-renderer html --web-port=8080"

echo.
echo ========================================
echo All services starting!
echo ========================================
echo Backend API: http://localhost:8000
echo Secondary API: http://localhost:8001
echo Flutter App: http://localhost:8080
echo.
echo Services are running in separate windows.
echo Close this window to keep services running.
echo.
pause
