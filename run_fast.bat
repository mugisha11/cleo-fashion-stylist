@echo off
echo Starting Fast Flutter Web Build...
echo.

REM Clean previous build
flutter clean

REM Build with HTML renderer (fastest)
echo Building with HTML renderer (fastest option)...
flutter build web --web-renderer html --release

REM Serve the built files
echo.
echo Build complete! Starting server...
cd build\web
python -m http.server 8080

