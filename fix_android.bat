@echo off
echo Fixing Android build issues...

echo Cleaning Flutter project...
call flutter clean

echo Updating AndroidX dependencies...
cd android
call gradlew --refresh-dependencies
cd ..

echo Reinstalling dependencies...
call flutter pub get

echo Done! Try running your app now.
pause