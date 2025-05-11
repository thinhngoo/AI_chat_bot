@echo off
REM filepath: c:\Project\AI_chat_bot\test_ci_complete.bat
echo Testing complete CI/CD pipeline locally
echo =====================================

REM Check if act is installed
where act >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Act is not installed. This tool helps run GitHub Actions locally.
    echo Install it from: https://github.com/nektos/act
    echo.
    set /p install_act=Would you like to install Act now? (y/n): 
    if /i "%install_act%"=="y" (
        echo Installing Act via Chocolatey...
        powershell -Command "if(!(Test-Path -Path \"$env:ProgramData\chocolatey\bin\choco.exe\")) { Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) }"
        choco install act-cli -y
    ) else (
        echo Skipping Act installation. Some tests may not work correctly.
    )
)

echo.
echo Step 1: Testing Flutter Build & Test workflow...
echo ---------------------------------------------
call flutter format --set-exit-if-changed .
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Code format issues found.
    echo.
)

call flutter analyze
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Static analysis issues found.
    echo.
)

call flutter test
if %ERRORLEVEL% NEQ 0 (
    echo Error: Tests are failing.
    echo.
) else (
    echo All tests passed!
    echo.
)

echo.
echo Step 2: Building Web...
echo -------------------
call flutter build web
if %ERRORLEVEL% NEQ 0 (
    echo Error: Web build failed.
    echo.
) else (
    echo Web build successful!
    echo.
)

echo.
echo Step 3: Testing Firebase Functions...
echo --------------------------------
if exist functions\package.json (
    cd functions
    call npm ci
    if %ERRORLEVEL% NEQ 0 (
        echo Error installing Functions dependencies.
        cd ..
    ) else (
        call npm run lint
        call npm run build
        cd ..
        if %ERRORLEVEL% NEQ 0 (
            echo Error: Functions build failed.
            echo.
        ) else {
            echo Functions build successful!
            echo.
        }
    )
) else (
    echo Firebase Functions not found or not configured properly.
    echo.
)

echo.
echo Step 4: Testing Firebase Hosting Configuration...
echo --------------------------------------------
where firebase >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Firebase CLI not installed. Install it with: npm install -g firebase-tools
    echo.
) else (
    call firebase hosting:channel:create ci-test --json || echo Creating or using existing channel...
    call firebase hosting:channel:deploy ci-test --only hosting --json
    if %ERRORLEVEL% NEQ 0 (
        echo Error: Firebase Hosting deployment test failed.
        echo.
    ) else {
        echo Firebase Hosting deployment test successful!
        echo.
        firebase hosting:channel:delete ci-test -f
    }
)

echo.
echo CI/CD pipeline test completed!
echo =========================
echo.
echo If all steps above were successful, your CI/CD pipeline should work correctly when pushed to GitHub.
echo For more information, check docs/ci_cd_setup_guide.md
echo.
