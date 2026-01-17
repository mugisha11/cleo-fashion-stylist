# All-in-One Script: Build and Share Cleo Fashion on the Internet
# This script prepares your app for sharing online

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Share Cleo Fashion on the Internet" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check Flutter
Write-Host "[1/4] Checking Flutter..." -ForegroundColor Yellow
flutter --version >nul 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter not found! Please install Flutter SDK" -ForegroundColor Red
    pause
    exit 1
}
Write-Host "✅ Flutter ready" -ForegroundColor Green
Write-Host ""

# Step 2: Verify Firebase Keys
Write-Host "[2/4] Checking Firebase configuration..." -ForegroundColor Yellow
$firebaseOptionsPath = "lib\firebase_options.dart"
if (Test-Path $firebaseOptionsPath) {
    $content = Get-Content $firebaseOptionsPath -Raw
    if ($content -match "apiKey: 'AIzaSy[^D]") {
        Write-Host "✅ Firebase Web API key configured" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Firebase Web API key may need updating" -ForegroundColor Yellow
        Write-Host "   Run: .\get_firebase_web_key.ps1" -ForegroundColor Gray
    }
} else {
    Write-Host "⚠️  firebase_options.dart not found" -ForegroundColor Yellow
}
Write-Host ""

# Step 3: Build Web App
Write-Host "[3/4] Building web app for production..." -ForegroundColor Yellow
Write-Host "   This may take 2-5 minutes..." -ForegroundColor Gray
flutter pub get >nul 2>&1
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    pause
    exit 1
}
Write-Host "✅ Build complete! Files in: build\web\" -ForegroundColor Green
Write-Host ""

# Step 4: Deployment Options
Write-Host "[4/4] Choose deployment method:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Firebase Hosting (Recommended - Free, Fast)" -ForegroundColor Cyan
Write-Host "2. Netlify (Easiest - Drag & Drop)" -ForegroundColor Cyan
Write-Host "3. Vercel (Great for GitHub integration)" -ForegroundColor Cyan
Write-Host "4. Just show me the build folder" -ForegroundColor Cyan
Write-Host ""
$choice = Read-Host "Enter choice (1-4)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "Deploying to Firebase Hosting..." -ForegroundColor Cyan
        if (-not (Test-Path "firebase.json")) {
            Write-Host "Initializing Firebase Hosting..." -ForegroundColor Yellow
            Write-Host "When prompted, set public directory to: build/web" -ForegroundColor Gray
            firebase init hosting --project ai-styling-c45cf
        }
        firebase deploy --only hosting
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "🎉 Your app is live!" -ForegroundColor Green
            Write-Host "Check: https://console.firebase.google.com/project/ai-styling-c45cf/hosting" -ForegroundColor Cyan
        }
    }
    "2" {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Netlify Deployment Instructions:" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "1. Go to: https://app.netlify.com/drop" -ForegroundColor White
        Write-Host "2. Drag the 'build\web' folder onto the page" -ForegroundColor White
        Write-Host "3. Your app will be live in seconds!" -ForegroundColor White
        Write-Host ""
        $openFolder = Read-Host "Open build folder now? (y/n)"
        if ($openFolder -eq "y" -or $openFolder -eq "Y") {
            Start-Process explorer.exe -ArgumentList "build\web"
        }
    }
    "3" {
        Write-Host ""
        Write-Host "Deploying to Vercel..." -ForegroundColor Cyan
        vercel --prod --cwd build/web 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Vercel CLI not found. Install with: npm install -g vercel" -ForegroundColor Yellow
            Write-Host "Or use: https://vercel.com/new" -ForegroundColor Yellow
        }
    }
    "4" {
        Write-Host ""
        Write-Host "Opening build folder..." -ForegroundColor Cyan
        if (Test-Path "build\web") {
            Start-Process explorer.exe -ArgumentList "build\web"
            Write-Host ""
            Write-Host "You can:" -ForegroundColor Yellow
            Write-Host "  - Upload to any web hosting service" -ForegroundColor White
            Write-Host "  - Use GitHub Pages" -ForegroundColor White
            Write-Host "  - Host on your own server" -ForegroundColor White
        }
    }
    default {
        Write-Host "Invalid choice. Opening build folder..." -ForegroundColor Yellow
        if (Test-Path "build\web") {
            Start-Process explorer.exe -ArgumentList "build\web"
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ Ready to share on the internet!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
