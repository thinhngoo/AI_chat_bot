@echo off
echo AI Chat Bot - Windows OAuth Setup
echo --------------------------------

echo This script will help you set up Google OAuth for Windows.
echo.
echo Prerequisites:
echo  1. A Google Cloud project with OAuth 2.0 credentials
echo  2. A Firebase project with Google authentication enabled
echo.

set /p continue=Do you want to continue? (y/n): 
if /i not "%continue%"=="y" (
    echo Setup canceled.
    exit /b 0
)

echo.
echo Step 1: Creating or updating .env file with OAuth credentials
echo.

if exist ".env" (
    echo Existing .env file found.
) else (
    echo Creating new .env file...
    echo # Google OAuth credentials> .env
    echo GEMINI_API_KEY=your_gemini_api_key_here>> .env
)

echo.
echo Please enter your Google OAuth credentials:
echo (You can find these in the Google Cloud Console)
echo.

set /p client_id=Desktop Client ID: 
set /p client_secret=Client Secret: 

if "%client_id%"=="" (
    echo Client ID cannot be empty.
    exit /b 1
)

if "%client_secret%"=="" (
    echo Client Secret cannot be empty.
    exit /b 1
)

echo.
echo Updating .env file with credentials...

powershell -Command "(Get-Content .env) -replace 'GOOGLE_DESKTOP_CLIENT_ID=.*', 'GOOGLE_DESKTOP_CLIENT_ID=%client_id%' | Set-Content .env"
powershell -Command "(Get-Content .env) -replace 'GOOGLE_CLIENT_SECRET=.*', 'GOOGLE_CLIENT_SECRET=%client_secret%' | Set-Content .env"

if not exist ".env" (
    echo Failed to update .env file.
    exit /b 1
)

echo.
echo IMPORTANT: Make sure to add this client ID to Firebase Console as well!
echo 1. Go to Firebase Console > Authentication > Sign-in method > Google
echo 2. Add this client ID to "Web SDK configuration" section
echo.

echo OAuth credentials set up successfully!
echo.

echo You can now build the application:
echo flutter build windows --release
echo.
