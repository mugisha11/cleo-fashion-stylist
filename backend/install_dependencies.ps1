# PowerShell script to install backend dependencies
# Handles dlib installation on Windows gracefully

Write-Host "🚀 Installing Cleo Fashion Backend Dependencies..." -ForegroundColor Cyan
Write-Host ""

# Check Python version
$pythonVersion = python --version 2>&1
Write-Host "Python version: $pythonVersion" -ForegroundColor Green

# Step 1: Install core dependencies (without dlib and face-recognition)
Write-Host ""
Write-Host "📦 Step 1: Installing core dependencies..." -ForegroundColor Yellow

$coreDeps = @(
    "fastapi==0.104.1",
    "uvicorn[standard]==0.24.0",
    "pydantic==2.5.0",
    "pydantic-settings==2.1.0",
    "python-multipart==0.0.6",
    "opencv-python==4.8.1.78",
    "opencv-contrib-python==4.8.1.78",
    "numpy",
    "Pillow",
    "scikit-image>=0.22.0",
    "torch>=2.1.0",
    "torchvision>=0.16.0",
    "mediapipe>=0.10.30",
    "httpx==0.25.1",
    "requests==2.31.0",
    "supabase==2.0.3",
    "postgrest==0.13.0",
    "python-dotenv==1.0.0",
    "aiofiles==23.2.1",
    "python-json-logger==2.0.7",
    "pytest==7.4.3",
    "pytest-asyncio==0.21.1",
    "ultralytics==8.0.196",
    "scikit-learn==1.3.2",
    "scipy>=1.11.0"
)

Write-Host "Installing core packages..." -ForegroundColor Gray
python -m pip install --upgrade pip
python -m pip install $coreDeps

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error installing core dependencies!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Core dependencies installed!" -ForegroundColor Green

# Step 2: Install VTON dependencies
Write-Host ""
Write-Host "📦 Step 2: Installing VTON dependencies..." -ForegroundColor Yellow

$vtonDeps = @(
    "diffusers==0.21.4",
    "transformers==4.35.0",
    "controlnet-aux==0.4.0",
    "accelerate==0.24.1"
)

Write-Host "Installing VTON packages..." -ForegroundColor Gray
python -m pip install $vtonDeps

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Warning: Some VTON dependencies failed to install" -ForegroundColor Yellow
    Write-Host "Continuing with optional dependencies..." -ForegroundColor Gray
}

Write-Host "✅ VTON dependencies installed!" -ForegroundColor Green

# Step 3: Try to install dlib (OPTIONAL - face recognition dependency)
Write-Host ""
Write-Host "📦 Step 3: Installing dlib (OPTIONAL - face recognition dependency)..." -ForegroundColor Yellow
Write-Host ""
Write-Host "⚠️  IMPORTANT: dlib compilation on Windows can take 10-15 minutes!" -ForegroundColor Red
Write-Host "   Face recognition is OPTIONAL - the VTON pipeline works without it" -ForegroundColor Gray
Write-Host ""
Write-Host "Options:" -ForegroundColor Cyan
Write-Host "  [s] Skip dlib/face-recognition (recommended for quick setup)" -ForegroundColor White
Write-Host "  [i] Install dlib (will take 10-15 minutes to compile)" -ForegroundColor White
Write-Host "  [c] Try conda (if you have Anaconda/Miniconda installed)" -ForegroundColor White
Write-Host ""

$response = Read-Host "Choose option (s/i/c) [default: s]"
if ([string]::IsNullOrWhiteSpace($response)) {
    $response = "s"
}

$dlibInstalled = $false

if ($response -eq 's' -or $response -eq 'S') {
    Write-Host "⏭️  Skipping dlib installation (face-recognition will be optional)" -ForegroundColor Yellow
} elseif ($response -eq 'c' -or $response -eq 'C') {
    Write-Host "Checking if conda is available..." -ForegroundColor Gray
    $condaAvailable = Get-Command conda -ErrorAction SilentlyContinue
    if ($condaAvailable) {
        Write-Host "Installing dlib via conda (this may take a few minutes)..." -ForegroundColor Gray
        conda install -c conda-forge dlib=19.24.2 -y
        if ($LASTEXITCODE -eq 0) {
            $dlibInstalled = $true
            Write-Host "✅ dlib installed via conda!" -ForegroundColor Green
        } else {
            Write-Host "❌ conda installation failed" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ conda not found. Please install Anaconda/Miniconda first." -ForegroundColor Red
        Write-Host "   Falling back to pip installation..." -ForegroundColor Gray
        $response = "i"
    }
}

if ($response -eq 'i' -or $response -eq 'I') {
    Write-Host ""
    Write-Host "⚠️  Starting dlib compilation - this will take 10-15 minutes!" -ForegroundColor Yellow
    Write-Host "   You can safely cancel (Ctrl+C) if you change your mind" -ForegroundColor Gray
    Write-Host "   The VTON pipeline will work without face-recognition" -ForegroundColor Gray
    Write-Host ""
    
    # Try to install dlib with progress visible
    Write-Host "Installing dlib (compiling from source - please wait)..." -ForegroundColor Gray
    python -m pip install dlib==19.24.2
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ dlib installed successfully!" -ForegroundColor Green
        $dlibInstalled = $true
    } else {
        Write-Host "❌ dlib installation failed (this is common on Windows)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Alternative options:" -ForegroundColor Cyan
        Write-Host "  1. Install Visual Studio Build Tools: https://visualstudio.microsoft.com/downloads/" -ForegroundColor White
        Write-Host "  2. Use conda: conda install -c conda-forge dlib" -ForegroundColor White
        Write-Host "  3. Skip it - face recognition is optional in the code" -ForegroundColor White
    }
}

# Step 4: Install face-recognition (only if dlib succeeded)
if ($dlibInstalled) {
    Write-Host ""
    Write-Host "📦 Step 4: Installing face-recognition..." -ForegroundColor Yellow
    python -m pip install face-recognition==1.3.0
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ face-recognition installed!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  face-recognition installation failed" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "⏭️  Skipping face-recognition (dlib not installed)" -ForegroundColor Yellow
    Write-Host "   Face recognition features will be optional in the code" -ForegroundColor Gray
}

# Step 5: Install optional GPU dependencies (if needed)
Write-Host ""
$installGPU = Read-Host "Do you want to install optional GPU dependencies (xformers, realesrgan)? (y/n)"
if ($installGPU -eq 'y' -or $installGPU -eq 'Y') {
    Write-Host "Installing optional GPU packages..." -ForegroundColor Gray
    
    $optionalDeps = @(
        "xformers==0.0.22.post7",
        "realesrgan==0.3.0"
    )
    
    python -m pip install $optionalDeps
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Optional GPU dependencies installed!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Some optional dependencies failed (this is okay)" -ForegroundColor Yellow
    }
}

# Final summary
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✅ Installation Complete!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

if (-not $dlibInstalled) {
    Write-Host "⚠️  Note: dlib and face-recognition were not installed." -ForegroundColor Yellow
    Write-Host "   The Sora VTON pipeline will work, but face recognition features may be limited." -ForegroundColor Gray
    Write-Host ""
}

Write-Host "To verify installation, run:" -ForegroundColor Cyan
Write-Host "  python -c `"import torch; import diffusers; print('Core packages OK')`"" -ForegroundColor White
Write-Host ""

if ($dlibInstalled) {
    Write-Host "To test face recognition:" -ForegroundColor Cyan
    Write-Host "  python -c `"import face_recognition; print('Face recognition OK')`"" -ForegroundColor White
    Write-Host ""
}

Write-Host "🚀 Ready to run the backend!" -ForegroundColor Green
