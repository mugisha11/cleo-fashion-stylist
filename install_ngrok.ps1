# Install ngrok without admin rights
# Downloads ngrok to a local folder and adds it to PATH for current session

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installing ngrok" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ngrokDir = "$env:USERPROFILE\ngrok"
$ngrokExe = "$ngrokDir\ngrok.exe"

# Check if ngrok already exists
if (Test-Path $ngrokExe) {
    Write-Host "✅ ngrok already installed at: $ngrokExe" -ForegroundColor Green
    Write-Host ""
    Write-Host "Adding to PATH for this session..." -ForegroundColor Yellow
    $env:Path += ";$ngrokDir"
    Write-Host "✅ ngrok is ready to use!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To make it permanent, add this to your PATH:" -ForegroundColor Yellow
    Write-Host "  $ngrokDir" -ForegroundColor White
    exit 0
}

# Create directory
Write-Host "Creating directory: $ngrokDir" -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $ngrokDir | Out-Null

# Download ngrok
Write-Host "Downloading ngrok..." -ForegroundColor Yellow
Write-Host "This may take a minute..." -ForegroundColor Gray
Write-Host ""

$downloadUrl = "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip"
$zipFile = "$env:TEMP\ngrok.zip"

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -UseBasicParsing
    Write-Host "✅ Download complete!" -ForegroundColor Green
    Write-Host ""
    
    # Extract
    Write-Host "Extracting ngrok..." -ForegroundColor Yellow
    Expand-Archive -Path $zipFile -DestinationPath $ngrokDir -Force
    Write-Host "✅ Extraction complete!" -ForegroundColor Green
    Write-Host ""
    
    # Clean up zip file
    Remove-Item $zipFile -Force -ErrorAction SilentlyContinue
    
    # Add to PATH for current session
    $env:Path += ";$ngrokDir"
    
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✅ ngrok installed successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Location: $ngrokExe" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "ngrok is now available in this session!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To make it permanent, add this to your PATH:" -ForegroundColor Yellow
    Write-Host "  $ngrokDir" -ForegroundColor White
    Write-Host ""
    Write-Host "Or run this command:" -ForegroundColor Yellow
    Write-Host "  [Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User') + ';$ngrokDir', 'User')" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "❌ Error downloading ngrok: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual installation:" -ForegroundColor Yellow
    Write-Host "1. Download from: https://ngrok.com/download" -ForegroundColor White
    Write-Host "2. Extract to: $ngrokDir" -ForegroundColor White
    Write-Host "3. Add to PATH" -ForegroundColor White
    exit 1
}
