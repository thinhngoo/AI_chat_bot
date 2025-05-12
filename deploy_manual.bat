@echo off
REM filepath: c:\Project\AI_chat_bot\deploy_manual.bat
echo AI Chat Bot Manual Deployment
echo ----------------------------

echo Which component would you like to deploy?
echo 1. Web App (Hosting)
echo 2. Firebase Functions
echo 3. All components
echo.

set /p choice="Enter your choice (1-3): "

if "%choice%"=="1" goto deploy_web
if "%choice%"=="2" goto deploy_functions
if "%choice%"=="3" goto deploy_all

echo Invalid choice. Exiting.
exit /b 1

:deploy_web
echo.
echo Deploying Web App to Firebase Hosting...
call flutter build web
if %ERRORLEVEL% NEQ 0 (
    echo Error: Web build failed.
    exit /b 1
)
call firebase deploy --only hosting
goto end

:deploy_functions
echo.
echo Deploying Firebase Functions...
cd functions
call npm install
call npm run build
cd ..
call firebase deploy --only functions
goto end

:deploy_all
echo.
echo Deploying all components...
call flutter build web
if %ERRORLEVEL% NEQ 0 (
    echo Error: Web build failed.
    exit /b 1
)
cd functions
call npm install
call npm run build
cd ..
call firebase deploy
goto end

:end
echo.
echo Deployment completed!
echo.
