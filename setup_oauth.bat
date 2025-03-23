@echo off
echo === Google OAuth Setup Helper ===
echo.
echo This script will help you set up your .env file for Google OAuth.
echo.

if exist .env (
  echo Found existing .env file.
  echo Checking for required variables...
  
  findstr /C:"GOOGLE_DESKTOP_CLIENT_ID" .env >nul
  if errorlevel 1 (
    echo GOOGLE_DESKTOP_CLIENT_ID not found in .env file.
  ) else (
    echo GOOGLE_DESKTOP_CLIENT_ID exists in .env file.
  )
  
  findstr /C:"GOOGLE_CLIENT_SECRET" .env >nul
  if errorlevel 1 (
    echo GOOGLE_CLIENT_SECRET not found in .env file.
  ) else (
    echo GOOGLE_CLIENT_SECRET exists in .env file.
  )
) else (
  echo No .env file found.
  echo Creating .env file from template...
  copy .env.example .env
  echo .env file created. Please edit it with your credentials.
)

echo.
echo === Reminder ===
echo.
echo Make sure to register these redirect URIs in Google Cloud Console:
echo - http://localhost:8080
echo - http://localhost:3000
echo.
echo Don't forget to add the same client ID to Firebase Console:
echo Authentication > Sign-in method > Google > Web SDK configuration
echo.
echo Press any key to open the OAUTH_SETUP_GUIDE.md file...
pause >nul

if exist OAUTH_SETUP_GUIDE.md (
  start OAUTH_SETUP_GUIDE.md
) else (
  echo Guide file not found.
)

echo.
echo Process completed.
pause
