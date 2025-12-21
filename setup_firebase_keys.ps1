# Firebase Keys Setup Helper Script
# This script helps you get Firebase API keys from the console

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Firebase API Keys Setup Helper" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 1: Opening Firebase Console..." -ForegroundColor Yellow
Start-Process "https://console.firebase.google.com/project/ai-styling-c45cf/settings/general"

Write-Host ""
Write-Host "Step 2: Follow these instructions:" -ForegroundColor Yellow
Write-Host "  1. Scroll down to 'Your apps' section" -ForegroundColor White
Write-Host "  2. If no Web app exists, click 'Add app' > Web (</> icon)" -ForegroundColor White
Write-Host "  3. Register the app with a nickname (e.g., 'Virtual Twin Web')" -ForegroundColor White
Write-Host "  4. Copy the config object that appears" -ForegroundColor White
Write-Host ""
Write-Host "Step 3: The config will look like this:" -ForegroundColor Yellow
Write-Host "  const firebaseConfig = {" -ForegroundColor Gray
Write-Host "    apiKey: 'AIzaSy...'," -ForegroundColor Gray
Write-Host "    authDomain: 'ai-styling-c45cf.firebaseapp.com'," -ForegroundColor Gray
Write-Host "    projectId: 'ai-styling-c45cf'," -ForegroundColor Gray
Write-Host "    storageBucket: 'ai-styling-c45cf.appspot.com'," -ForegroundColor Gray
Write-Host "    messagingSenderId: '102834305158'," -ForegroundColor Gray
Write-Host "    appId: '1:102834305158:web:...'" -ForegroundColor Gray
Write-Host "  };" -ForegroundColor Gray
Write-Host ""
Write-Host "Step 4: Copy the apiKey and appId values" -ForegroundColor Yellow
Write-Host "Step 5: Update lib/firebase_options.dart with these values" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press any key when you have the keys..." -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Write-Host ""
Write-Host "Opening firebase_options.dart for editing..." -ForegroundColor Cyan
code lib/firebase_options.dart

