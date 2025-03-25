@echo off
echo AI Chat Bot - Windows Build Troubleshooter
echo -----------------------------------------

echo This script will fix common issues with Windows builds:
echo 1. Clear build cache
echo 2. Re-download dependencies
echo 3. Fix Flutter Windows plugin registration
echo 4. Copy required DLLs to the output directory

echo.
echo Step 1: Cleaning project...
call flutter clean
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Clean failed, but continuing...
)

echo.
echo Step 2: Getting dependencies...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo Failed to get dependencies.
    exit /b 1
)

echo.
echo Step 3: Fixing plugin registration...
rmdir /s /q .dart_tool\flutter_build 2>nul
call flutter pub get

echo.
echo Step 4: Fixing FlutterFire initialization...
if exist "lib\firebase_options.dart" (
    echo FirebaseOptions file found, skipping creation.
) else (
    echo WARNING: firebase_options.dart not found. 
    echo You may need to run: flutterfire configure
)

echo.
echo Step 5: Checking environment files...
if exist ".env" (
    echo .env file found, skipping creation.
) else (
    echo WARNING: .env file not found.
    echo Creating a template .env file...
    echo GEMINI_API_KEY=your_gemini_api_key_here> .env
    echo GOOGLE_DESKTOP_CLIENT_ID=your_desktop_client_id_here>> .env
    echo GOOGLE_CLIENT_SECRET=your_client_secret_here>> .env
    echo Please update the .env file with your actual API keys.
)

echo.
echo Step 6: Setting up OAuth for Windows...
if exist "setup_oauth.bat" (
    echo OAuth setup script found. Do you want to run it now? (y/n)
    set /p run_oauth=
    if /i "%run_oauth%"=="y" (
        call setup_oauth.bat
    ) else (
        echo Skipping OAuth setup.
    )
) else (
    echo WARNING: setup_oauth.bat not found.
)

echo.
echo Fixes applied! Now try building again:
echo flutter build windows --release
echo.
