@echo off
REM filepath: c:\Project\AI_chat_bot\test_ci_local.bat
echo Testing CI/CD configuration locally
echo ------------------------------------

echo Step 1: Checking code formatting...
call flutter format --set-exit-if-changed .
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Code formatting issues detected.
    echo Please run 'flutter format .' to fix.
    echo.
)

echo Step 2: Running static analysis...
call flutter analyze
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Static analysis found issues.
    echo Please fix the issues before pushing to GitHub.
    echo.
)

echo Step 3: Running tests...
call flutter test
if %ERRORLEVEL% NEQ 0 (
    echo Error: Tests failed.
    echo Please fix failing tests before pushing to GitHub.
    exit /b 1
)

echo Step 4: Building web app...
call flutter build web
if %ERRORLEVEL% NEQ 0 (
    echo Error: Web build failed.
    exit /b 1
)

echo Step 5: Checking Firebase Functions...
if exist functions\package.json (
    cd functions
    call npm install
    call npm run lint
    call npm run build
    cd ..
    if %ERRORLEVEL% NEQ 0 (
        echo Error: Firebase Functions build failed.
        exit /b 1
    )
)

echo.
echo All CI checks passed successfully!
echo You can now push your changes to GitHub.
echo.
