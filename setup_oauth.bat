@echo off
echo Jarvis API Setup Helper
echo =======================
echo.
echo This script will help you set up your .env file for Jarvis API integration.
echo.

if exist .env (
  echo Found existing .env file.
  set /p overwrite="Do you want to overwrite it? (y/n): "
  if /i "%overwrite%" neq "y" (
    echo Setup cancelled. Your existing .env file was not modified.
    goto :end
  )
)

echo Creating .env file from template...
copy .env.example .env > nul
echo .env file created.
echo.
echo Please edit the .env file with your Jarvis API credentials:
echo.
echo - AUTH_API_URL: URL for the Jarvis Auth API
echo - JARVIS_API_URL: URL for the Jarvis API
echo - JARVIS_API_KEY: Your Jarvis API key
echo - STACK_PROJECT_ID: Your Stack Project ID
echo - STACK_PUBLISHABLE_CLIENT_KEY: Your Stack Publishable Client Key
echo.
echo You can obtain these credentials from the Jarvis developer portal.
echo.
echo Setup completed. Please update the .env file with your actual credentials.

:end
pause
