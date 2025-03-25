@echo off
echo Building AI Chat Bot for Windows...
echo -----------------------------------

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Flutter not found in PATH. Please install Flutter and add it to your PATH.
    exit /b 1
)

REM Check Flutter version
flutter --version | findstr "3.29.1" >nul
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Flutter version may not be 3.29.1. Recommended version is 3.29.1 or higher.
    echo Current Flutter version:
    flutter --version
    echo.
    timeout /t 2 >nul
)

echo Getting dependencies...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo Failed to get dependencies.
    exit /b 1
)

echo.
echo Running static analysis...
call flutter analyze
if %ERRORLEVEL% NEQ 0 (
    echo Warning: Static analysis found issues. You may want to fix them before building.
    echo Press any key to continue anyway or Ctrl+C to cancel.
    pause >nul
)

echo.
echo Building Windows application...
call flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo Build failed.
    exit /b 1
)

echo.
echo Build successful! The executable is available at:
echo build\windows\x64\runner\Release\flutter_application_1.exe

echo.
echo To fix common Windows build issues, run fix_windows_build.bat if you encounter any problems.
