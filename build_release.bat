@echo off
:: RateMe release build with obfuscation
:: Symbols are written to build\debug-info\ for crash de-obfuscation.
:: Keep that folder safe — never ship it or commit it.

set SYMBOL_DIR=build\debug-info

echo Building Android APK...
flutter build apk --release --obfuscate --split-debug-info=%SYMBOL_DIR%\android

echo.
echo Building Android App Bundle...
flutter build appbundle --release --obfuscate --split-debug-info=%SYMBOL_DIR%\android-aab

echo.
echo Done. Symbols saved to %SYMBOL_DIR%\
echo WARNING: Keep the debug-info folder — you need it to decode crash stack traces.
