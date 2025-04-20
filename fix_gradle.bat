@echo off
echo Fixing Gradle initialization script issues...

rem Create .gradle folder if it doesn't exist
if not exist "%USERPROFILE%\.gradle" mkdir "%USERPROFILE%\.gradle"

rem Create or update init.gradle to skip the problematic Red Hat Java extension initialization
echo // Custom initialization script > "%USERPROFILE%\.gradle\init.gradle"
echo allprojects { >> "%USERPROFILE%\.gradle\init.gradle"
echo     buildscript { >> "%USERPROFILE%\.gradle\init.gradle"
echo         // Skip problematic Red Hat Java extension initialization script >> "%USERPROFILE%\.gradle\init.gradle"
echo     } >> "%USERPROFILE%\.gradle\init.gradle"
echo } >> "%USERPROFILE%\.gradle\init.gradle"

echo Created custom init.gradle to fix initialization script issues

rem Clean the project
cd %~dp0
call flutter clean

echo.
echo Gradle configuration fixed! Try running your Flutter app now with:
echo flutter run
