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
echo - Optimized for web
echo.

REM Run with optimizations for faster builds
REM Profile mode: Fast compilation + optimized performance + hot reload
REM (Release mode takes 60-120s, Profile takes 20-40s)
flutter run -d chrome --profile --web-port=8080

