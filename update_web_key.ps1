# Quick script to update Web API key in firebase_options.dart

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Update Firebase Web API Key" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Please provide the Web API key and App ID from 'Virtual Twin Web' app:" -ForegroundColor Yellow
Write-Host ""

$webApiKey = Read-Host "Enter Web API Key (starts with AIzaSy)"
$webAppId = Read-Host "Enter Web App ID (format: 1:102834305158:web:XXXXX)"

if ($webApiKey -and $webAppId) {
    Write-Host ""
    Write-Host "Updating firebase_options.dart..." -ForegroundColor Green
    
    $filePath = "lib\firebase_options.dart"
    $content = Get-Content $filePath -Raw
    
    # Update Web API key
    $content = $content -replace "apiKey: 'AIzaSyDummyKeyForDevelopment', // ⚠️ REPLACE WITH REAL WEB API KEY.*", "apiKey: '$webApiKey',"
    $content = $content -replace "appId: '1:102834305158:web:dummy', // ⚠️ REPLACE WITH REAL WEB APP ID.*", "appId: '$webAppId',"
    
    Set-Content -Path $filePath -Value $content -NoNewline
    
    Write-Host "✅ Updated firebase_options.dart with Web API key!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Web API Key: $webApiKey" -ForegroundColor Gray
    Write-Host "Web App ID: $webAppId" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Now hot reload or restart your Flutter app!" -ForegroundColor Yellow
} else {
    Write-Host "❌ Both values are required. Please run the script again." -ForegroundColor Red
}
