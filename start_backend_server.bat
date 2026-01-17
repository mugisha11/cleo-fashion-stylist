@echo off
echo ========================================
echo Starting Cleo Fashion Backend Server
echo ========================================
echo.

cd backend

echo Checking Python installation...
python --version
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.8+ and try again
    pause
    exit /b 1
)

echo.
echo Checking if .env file exists...
if not exist .env (
    echo WARNING: .env file not found!
    echo Please create .env file with your API keys
    echo See .env.example for reference
    echo.
)

echo.
echo Installing/updating dependencies...
pip install -r requirements.txt --quiet
if errorlevel 1 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo ========================================
echo Starting server at http://localhost:8000
echo ========================================
echo.
echo Server will be available at:
echo   - Health: http://localhost:8000/health
echo   - Production VTON: http://localhost:8000/production-vton
echo.
echo Press Ctrl+C to stop the server
echo.

python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

pause
