@echo off
echo ========================================
echo Starting Cleo Fashion - OPTIMIZED FAST BUILD
echo ========================================
echo.

REM Check if Flutter is available
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter not found! Please install Flutter SDK
    pause
    exit /b 1
)

echo Building with optimizations:
echo - Profile mode (faster than debug, keeps hot reload)
echo - HTML renderer (faster than CanvasKit)
echo - Disabled sound null safety checks
echo - Optimized for web
echo.

REM Clean build cache for fresh start (optional - comment out if not needed)
REM flutter clean

REM Run with optimizations
REM Note: --web-renderer flag removed in Flutter 3.24+, HTML renderer is now default
flutter run -d chrome --profile --web-port=8080
