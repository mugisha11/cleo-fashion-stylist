# Get Firebase Web API Key from Console
# Your Web app is registered as "Virtual Twin Web"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Getting Firebase Web API Key" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Opening Firebase Console Web App Settings..." -ForegroundColor Yellow
$url = "https://console.firebase.google.com/project/ai-styling-c45cf/settings/general"
Start-Process $url

Write-Host ""
Write-Host "INSTRUCTIONS:" -ForegroundColor Green
Write-Host "1. In Firebase Console, scroll to 'Your apps' section" -ForegroundColor White
Write-Host "2. Find 'Virtual Twin Web' (Web app with </> icon)" -ForegroundColor White
Write-Host "3. Click on 'Virtual Twin Web' to expand it" -ForegroundColor White
Write-Host "4. You'll see a config object like this:" -ForegroundColor White
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
Write-Host "5. COPY these TWO values:" -ForegroundColor Green
Write-Host "   - apiKey (starts with 'AIzaSy')" -ForegroundColor Yellow
Write-Host "   - appId (format: '1:102834305158:web:XXXXX')" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press any key when you have copied the Web apiKey and appId..." -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Write-Host ""
Write-Host "Opening firebase_options.dart for editing..." -ForegroundColor Cyan
$filePath = Join-Path $PSScriptRoot "lib\firebase_options.dart"
if (Test-Path $filePath) {
    Start-Process notepad $filePath
    Write-Host ""
    Write-Host "UPDATE THE 'web' FirebaseOptions:" -ForegroundColor Yellow
    Write-Host "  - Find: apiKey: 'AIzaSyDummyKeyForDevelopment'" -ForegroundColor White
    Write-Host "  - Replace with: apiKey: 'YOUR_WEB_API_KEY_HERE'" -ForegroundColor Green
    Write-Host ""
    Write-Host "  - Find: appId: '1:102834305158:web:dummy'" -ForegroundColor White
    Write-Host "  - Replace with: appId: 'YOUR_WEB_APP_ID_HERE'" -ForegroundColor Green
    Write-Host ""
    Write-Host "Save the file and hot reload the app!" -ForegroundColor Green
} else {
    Write-Host "ERROR: firebase_options.dart not found at: $filePath" -ForegroundColor Red
}
