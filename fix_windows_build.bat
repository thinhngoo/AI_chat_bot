@echo off
echo Fixing Windows build configuration...

echo Configuring Firebase Auth for Windows...

REM Create backup
copy /Y windows\flutter\generated_plugin_registrant.cc windows\flutter\generated_plugin_registrant.cc.bak

REM Remove EXCLUDE_FIREBASE_AUTH to use new compatible version
findstr /v "EXCLUDE_FIREBASE_AUTH" windows\CMakeLists.txt > windows\CMakeLists.txt.new
move /Y windows\CMakeLists.txt.new windows\CMakeLists.txt

REM Create updated plugin registration file
(
echo //
echo //  Generated file. Do not edit.
echo //
echo.
echo // clang-format off
echo.
echo #include "generated_plugin_registrant.h"
echo.
echo // Firebase packages
echo #include ^<firebase_auth/firebase_auth_plugin_c_api.h^>
echo #include ^<firebase_core/firebase_core_plugin_c_api.h^>
echo.
echo void RegisterPlugins(flutter::PluginRegistry* registry) {
echo   FirebaseAuthPluginCApiRegisterWithRegistrar(
echo       registry-^>GetRegistrarForPlugin("FirebaseAuthPluginCApi"));
echo   FirebaseCorePluginCApiRegisterWithRegistrar(
echo       registry-^>GetRegistrarForPlugin("FirebaseCorePluginCApi"));
echo }
) > windows\flutter\generated_plugin_registrant.cc.new

REM Replace the original file with the new one
move /Y windows\flutter\generated_plugin_registrant.cc.new windows\flutter\generated_plugin_registrant.cc

echo Firebase Auth configured for Windows

echo Cleaning previous build artifacts...
rd /s /q build\windows 2>nul
flutter clean
flutter pub get

echo Done configuring Windows build
