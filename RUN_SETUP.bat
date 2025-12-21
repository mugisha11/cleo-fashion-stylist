@echo off
echo ========================================
echo Supabase Bucket Setup Script
echo ========================================
echo.
echo This script will create the 'wardrobe' bucket in Supabase.
echo.
echo First, you need to get your service role key:
echo   1. Go to: https://supabase.com/dashboard/project/kjiqtspkvnwgjoerpyxb/settings/api
echo   2. Find the "service_role" key (secret)
echo   3. Copy it
echo.
set /p SERVICE_KEY="Paste your service role key here: "
echo.
echo Creating bucket...
python setup_supabase_bucket.py --key "%SERVICE_KEY%"
echo.
pause
