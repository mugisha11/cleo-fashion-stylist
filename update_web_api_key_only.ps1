# Quick script to update ONLY the Web API key (App ID already updated)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Update Firebase Web API Key" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Web App ID is already set: 1:102834305158:web:4e292f13f0b8f847c6f907" -ForegroundColor Green
Write-Host ""
Write-Host "Please provide the Web API Key from 'Virtual Twin Web' app:" -ForegroundColor Yellow
Write-Host "(It should start with 'AIzaSy')" -ForegroundColor Gray
Write-Host ""

$webApiKey = Read-Host "Enter Web API Key"

if ($webApiKey -and $webApiKey.StartsWith('AIzaSy')) {
    Write-Host ""
    Write-Host "Updating firebase_options.dart..." -ForegroundColor Green
    
    $filePath = "lib\firebase_options.dart"
    $content = Get-Content $filePath -Raw
    
    # Update Web API key only
    $content = $content -replace "apiKey: 'AIzaSyDummyKeyForDevelopment', // ⚠️ REPLACE WITH REAL WEB API KEY.*", "apiKey: '$webApiKey', // ✅ Real Web API Key"
    
    Set-Content -Path $filePath -Value $content -NoNewline
    
    Write-Host "✅ Updated firebase_options.dart with Web API key!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Web API Key: $webApiKey" -ForegroundColor Gray
    Write-Host "Web App ID: 1:102834305158:web:4e292f13f0b8f847c6f907" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🎉 Firebase Web configuration is now COMPLETE!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Hot reload or restart your Flutter app to use Firebase Auth!" -ForegroundColor Yellow
} else {
    Write-Host "❌ Invalid API key. It should start with 'AIzaSy'. Please try again." -ForegroundColor Red
}
