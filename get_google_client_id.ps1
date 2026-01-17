# Get Google Client ID Helper Script
# This script helps you find your Google Client ID for web/index.html

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Google Sign-In Client ID Helper" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "To configure Google Sign-In, you need your Web Client ID." -ForegroundColor Yellow
Write-Host ""

Write-Host "Option 1: Get from Firebase Console (Easiest)" -ForegroundColor Green
Write-Host "  1. Open: https://console.firebase.google.com/project/ai-styling-c45cf/authentication/providers" -ForegroundColor White
Write-Host "  2. Click on 'Google' provider" -ForegroundColor White
Write-Host "  3. Enable it if not already enabled" -ForegroundColor White
Write-Host "  4. Copy the 'Web client ID' shown there" -ForegroundColor White
Write-Host ""

Write-Host "Option 2: Get from Google Cloud Console" -ForegroundColor Green
Write-Host "  1. Open: https://console.cloud.google.com/apis/credentials?project=ai-styling-c45cf" -ForegroundColor White
Write-Host "  2. Look for 'OAuth 2.0 Client IDs'" -ForegroundColor White
Write-Host "  3. Find the one with type 'Web application'" -ForegroundColor White
Write-Host "  4. Copy the 'Client ID'" -ForegroundColor White
Write-Host ""

Write-Host "After getting your Client ID:" -ForegroundColor Yellow
Write-Host "  1. Open: web\index.html" -ForegroundColor White
Write-Host "  2. Find line 25 (or search for 'google-signin-client_id')" -ForegroundColor White
Write-Host "  3. Replace 'YOUR_GOOGLE_CLIENT_ID' with your actual Client ID" -ForegroundColor White
Write-Host "  4. Save the file" -ForegroundColor White
Write-Host "  5. Restart your Flutter app" -ForegroundColor White
Write-Host ""

$openFirebase = Read-Host "Open Firebase Console in browser? (y/n)"
if ($openFirebase -eq "y" -or $openFirebase -eq "Y") {
    Start-Process "https://console.firebase.google.com/project/ai-styling-c45cf/authentication/providers"
}

Write-Host ""
Write-Host "For detailed instructions, see: GOOGLE_SIGNIN_SETUP.md" -ForegroundColor Cyan
Write-Host ""
