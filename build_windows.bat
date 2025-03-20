@echo off
echo Running Flutter doctor to verify environment...
flutter doctor -v

echo Updating dependencies...
flutter pub upgrade
flutter pub get

echo Building for Windows...
flutter build windows --verbose

echo Build completed.
pause
