# Firebase Web API Key Retrieval Helper
# This script helps you get the REAL Web API key from Firebase Console

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Firebase Web API Key Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Opening Firebase Console..." -ForegroundColor Yellow
$url = "https://console.firebase.google.com/project/ai-styling-c45cf/settings/general"
Start-Process $url

Write-Host ""
Write-Host "INSTRUCTIONS:" -ForegroundColor Green
Write-Host "1. Scroll down to 'Your apps' section" -ForegroundColor White
Write-Host "2. Look for a Web app (</> icon)" -ForegroundColor White
Write-Host "   - If NO Web app exists:" -ForegroundColor Yellow
Write-Host "     * Click 'Add app' > Select Web (</> icon)" -ForegroundColor Gray
Write-Host "     * Register with nickname: 'Cleo Fashion Web'" -ForegroundColor Gray
Write-Host "     * Click 'Register app'" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Once Web app is registered, you'll see a config like:" -ForegroundColor White
Write-Host ""
Write-Host "   const firebaseConfig = {" -ForegroundColor Cyan
Write-Host "     apiKey: 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXX'," -ForegroundColor Yellow
Write-Host "     authDomain: 'ai-styling-c45cf.firebaseapp.com'," -ForegroundColor Gray
Write-Host "     projectId: 'ai-styling-c45cf'," -ForegroundColor Gray
Write-Host "     storageBucket: 'ai-styling-c45cf.appspot.com'," -ForegroundColor Gray
Write-Host "     messagingSenderId: '102834305158'," -ForegroundColor Gray
Write-Host "     appId: '1:102834305158:web:XXXXXXXXXXXXXXXX'" -ForegroundColor Yellow
Write-Host "   };" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. COPY these TWO values:" -ForegroundColor Green
Write-Host "   - apiKey (starts with 'AIzaSy')" -ForegroundColor Yellow
Write-Host "   - appId (format: '1:102834305158:web:XXXXX')" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press any key when you have copied the apiKey and appId..." -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Write-Host ""
Write-Host "Opening firebase_options.dart for editing..." -ForegroundColor Cyan
$filePath = Join-Path $PSScriptRoot "lib\firebase_options.dart"
if (Test-Path $filePath) {
    Start-Process notepad $filePath
    Write-Host ""
    Write-Host "UPDATE THE 'web' FirebaseOptions:" -ForegroundColor Yellow
    Write-Host "  - Replace 'AIzaSyDummyKeyForDevelopment' with your REAL apiKey" -ForegroundColor White
    Write-Host "  - Replace '1:102834305158:web:dummy' with your REAL appId" -ForegroundColor White
    Write-Host ""
    Write-Host "Save the file and run: flutter run -d chrome" -ForegroundColor Green
} else {
    Write-Host "ERROR: firebase_options.dart not found at: $filePath" -ForegroundColor Red
}
