@echo off
echo Fixing Windows build configuration...

echo Configuring Firebase Auth for Windows...

REM Create backup
copy /Y windows\flutter\generated_plugin_registrant.cc windows\flutter\generated_plugin_registrant.cc.bak

REM Update CMakeLists.txt to use Firebase
echo Updating CMakeLists.txt...
powershell -Command "(Get-Content windows\CMakeLists.txt) -replace '#include \"firebase_auth\"', 'include(\"firebase_auth\")' | Set-Content windows\CMakeLists.txt"
powershell -Command "(Get-Content windows\CMakeLists.txt) -replace '#include \"firebase_core\"', 'include(\"firebase_core\")' | Set-Content windows\CMakeLists.txt"

REM Create updated plugin registration file
echo Creating updated plugin registrant...
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
echo #include ^<url_launcher_windows/url_launcher_windows.h^>
echo #include ^<cloud_firestore/cloud_firestore_plugin_c_api.h^>
echo.
echo void RegisterPlugins(flutter::PluginRegistry* registry) {
echo   FirebaseAuthPluginCApiRegisterWithRegistrar(
echo       registry-^>GetRegistrarForPlugin("FirebaseAuthPluginCApi"));
echo   FirebaseCorePluginCApiRegisterWithRegistrar(
echo       registry-^>GetRegistrarForPlugin("FirebaseCorePluginCApi"));
echo   UrlLauncherWindowsRegisterWithRegistrar(
echo       registry-^>GetRegistrarForPlugin("UrlLauncherWindows"));
echo   CloudFirestorePluginCApiRegisterWithRegistrar(
echo       registry-^>GetRegistrarForPlugin("CloudFirestorePluginCApi"));
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
