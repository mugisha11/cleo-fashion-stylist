# Get Google Client ID from Firebase Console
# Since Google Sign-In is already enabled, this script helps you find the Client ID

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Get Google Client ID (Already Enabled!)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ Google Sign-In is already enabled in Firebase!" -ForegroundColor Green
Write-Host ""
Write-Host "Now you need to get the Web Client ID:" -ForegroundColor Yellow
Write-Host ""

Write-Host "Method 1: From Google Sign-In Settings (Easiest)" -ForegroundColor Green
Write-Host "  1. In Firebase Console, click on 'Google' under Sign-in providers" -ForegroundColor White
Write-Host "  2. You'll see a section showing your Web client ID" -ForegroundColor White
Write-Host "  3. Copy the Client ID (looks like: 123456789-xxxxx.apps.googleusercontent.com)" -ForegroundColor White
Write-Host ""

Write-Host "Method 2: From Google Cloud Console" -ForegroundColor Green
Write-Host "  1. Go to: https://console.cloud.google.com/apis/credentials?project=ai-styling-c45cf" -ForegroundColor White
Write-Host "  2. Look for 'OAuth 2.0 Client IDs'" -ForegroundColor White
Write-Host "  3. Find the one with type 'Web application'" -ForegroundColor White
Write-Host "  4. Copy the 'Client ID'" -ForegroundColor White
Write-Host ""

$openGoogle = Read-Host "Open Google Sign-In settings in Firebase Console? (y/n)"
if ($openGoogle -eq "y" -or $openGoogle -eq "Y") {
    Start-Process "https://console.firebase.google.com/project/ai-styling-c45cf/authentication/providers"
    Write-Host ""
    Write-Host "Once you have the Client ID, I'll help you update web/index.html" -ForegroundColor Cyan
    Write-Host ""
    $clientId = Read-Host "Paste your Google Client ID here (or press Enter to skip)"
    
    if ($clientId -and $clientId -ne "" -and -not $clientId.Contains("YOUR_GOOGLE_CLIENT_ID")) {
        Write-Host ""
        Write-Host "Updating web/index.html..." -ForegroundColor Yellow
        
        $indexHtmlPath = "web\index.html"
        if (Test-Path $indexHtmlPath) {
            $content = Get-Content $indexHtmlPath -Raw
            $content = $content -replace 'YOUR_GOOGLE_CLIENT_ID\.apps\.googleusercontent\.com', "$clientId"
            Set-Content -Path $indexHtmlPath -Value $content -NoNewline
            
            Write-Host "✅ Updated web/index.html with your Client ID!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Next steps:" -ForegroundColor Yellow
            Write-Host "  1. Restart your Flutter app" -ForegroundColor White
            Write-Host "  2. Try 'Continue with Google' button" -ForegroundColor White
            Write-Host ""
        } else {
            Write-Host "❌ Could not find web/index.html" -ForegroundColor Red
        }
    } else {
        Write-Host ""
        Write-Host "No Client ID provided. You can manually update web/index.html:" -ForegroundColor Yellow
        Write-Host "  1. Open: web\index.html" -ForegroundColor White
        Write-Host "  2. Find line 39 (search for 'google-signin-client_id')" -ForegroundColor White
        Write-Host "  3. Replace 'YOUR_GOOGLE_CLIENT_ID' with your actual Client ID" -ForegroundColor White
        Write-Host ""
    }
} else {
    Write-Host ""
    Write-Host "To manually update:" -ForegroundColor Yellow
    Write-Host "  1. Get your Client ID from Firebase Console" -ForegroundColor White
    Write-Host "  2. Open: web\index.html" -ForegroundColor White
    Write-Host "  3. Replace 'YOUR_GOOGLE_CLIENT_ID' on line 39" -ForegroundColor White
    Write-Host ""
}

Write-Host "For detailed instructions, see: GOOGLE_SIGNIN_SETUP.md" -ForegroundColor Cyan
Write-Host ""
