# Share Flutter Web App Online using ngrok
# This script runs Flutter web server and exposes it via ngrok

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Share Cleo Fashion Online" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is available
Write-Host "Checking Flutter..." -ForegroundColor Yellow
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCmd) {
    Write-Host "❌ Flutter not found! Please install Flutter SDK" -ForegroundColor Red
    pause
    exit 1
}
Write-Host "✅ Flutter found!" -ForegroundColor Green
Write-Host ""

# Check if ngrok is available
Write-Host "Checking ngrok..." -ForegroundColor Yellow
$ngrokCmd = Get-Command ngrok -ErrorAction SilentlyContinue
if (-not $ngrokCmd) {
    # Try to find ngrok in common locations
    $ngrokPaths = @(
        "$env:USERPROFILE\ngrok\ngrok.exe",
        "$env:LOCALAPPDATA\ngrok\ngrok.exe",
        "C:\ngrok\ngrok.exe"
    )
    
    $ngrokFound = $false
    foreach ($path in $ngrokPaths) {
        if (Test-Path $path) {
            $ngrokDir = Split-Path $path -Parent
            $env:Path += ";$ngrokDir"
            $ngrokFound = $true
            Write-Host "✅ Found ngrok at: $path" -ForegroundColor Green
            break
        }
    }
    
    if (-not $ngrokFound) {
        Write-Host "❌ ngrok not found!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Installing ngrok automatically..." -ForegroundColor Yellow
        & "$PSScriptRoot\install_ngrok.ps1"
        if ($LASTEXITCODE -eq 0) {
            $env:Path += ";$env:USERPROFILE\ngrok"
            Write-Host "✅ ngrok installed and ready!" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to install ngrok automatically." -ForegroundColor Red
            Write-Host "Please run: .\install_ngrok.ps1" -ForegroundColor Yellow
            pause
            exit 1
        }
    }
} else {
    Write-Host "✅ ngrok found!" -ForegroundColor Green
}
Write-Host ""

# Set the port
$port = 8080
Write-Host "Using port: $port" -ForegroundColor Cyan
Write-Host ""

# Kill any existing Flutter or ngrok processes on this port
Write-Host "Cleaning up any existing processes..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -like "*flutter*" -or $_.ProcessName -like "*dart*"} | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process | Where-Object {$_.ProcessName -like "*ngrok*"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Write-Host "✅ Cleanup complete!" -ForegroundColor Green
Write-Host ""

# Start ngrok in background
Write-Host "Starting ngrok tunnel on port $port..." -ForegroundColor Cyan
$ngrokProcess = Start-Process -FilePath "ngrok" -ArgumentList "http", $port -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 3

# Get ngrok URL
Write-Host "Getting ngrok public URL..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -Method Get -ErrorAction Stop
    if ($response.tunnels -and $response.tunnels.Count -gt 0) {
        $publicUrl = $response.tunnels[0].public_url
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "✅ Your app is now online!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "🌐 Public URL: $publicUrl" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Share this URL with anyone to access your app!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Note: This URL will change each time you restart ngrok" -ForegroundColor Gray
        Write-Host "      (unless you have a paid ngrok account with static domain)" -ForegroundColor Gray
        Write-Host ""
    } else {
        Write-Host "⚠️  ngrok started but couldn't get URL. Check ngrok dashboard: http://localhost:4040" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Couldn't get ngrok URL automatically. Check ngrok dashboard: http://localhost:4040" -ForegroundColor Yellow
    Write-Host "   Error: $_" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Starting Flutter web server on port $port..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop both Flutter and ngrok" -ForegroundColor Yellow
Write-Host ""

# Start Flutter web server
flutter run -d web-server --web-port=$port

# Cleanup when Flutter stops
Write-Host ""
Write-Host "Stopping ngrok..." -ForegroundColor Yellow
Stop-Process -Id $ngrokProcess.Id -Force -ErrorAction SilentlyContinue
Write-Host "✅ Done!" -ForegroundColor Green
