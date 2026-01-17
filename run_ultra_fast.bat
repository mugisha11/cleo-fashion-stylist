@echo off
echo ========================================
echo Starting Cleo Fashion - ULTRA FAST BUILD
echo ========================================
echo.

REM Check if Flutter is available
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter not found! Please install Flutter SDK
    pause
    exit /b 1
)

echo Building with MAXIMUM optimizations:
echo - Release mode (fastest build and runtime)
echo - No debugging overhead
echo - Optimized compilation
echo.

REM Run in release mode for fastest build
flutter run -d chrome --release --web-port=8080
