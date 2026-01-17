# Enable People API for Google Sign-In
# This API is required for Google Sign-In to work properly

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Enable People API for Google Sign-In" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "The People API needs to be enabled for Google Sign-In to work." -ForegroundColor Yellow
Write-Host ""

Write-Host "Opening Google Cloud Console to enable People API..." -ForegroundColor Green
Start-Process "https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=102834305158"

Write-Host ""
Write-Host "Steps to enable:" -ForegroundColor Yellow
Write-Host "  1. Click the 'ENABLE' button on the page that opens" -ForegroundColor White
Write-Host "  2. Wait a few seconds for it to activate" -ForegroundColor White
Write-Host "  3. Come back and try Google Sign-In again" -ForegroundColor White
Write-Host ""

Write-Host "Note: It may take 1-2 minutes for the API to fully activate." -ForegroundColor Gray
Write-Host ""

$done = Read-Host "Press Enter after you've enabled the API..."

Write-Host ""
Write-Host "✅ People API should now be enabled!" -ForegroundColor Green
Write-Host ""
Write-Host "Try Google Sign-In again in your app." -ForegroundColor Cyan
Write-Host ""
