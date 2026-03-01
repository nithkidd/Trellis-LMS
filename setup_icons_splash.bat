@echo off
REM Setup script for Trellis app icons and splash screens

echo.
echo ========================================
echo Trellis - App Icons & Splash Setup
echo ========================================
echo.

echo Step 1: Getting dependencies...
call flutter pub get
echo ✓ Dependencies updated

echo.
echo Step 2: Generating app launcher icons...
call flutter pub run flutter_launcher_icons
echo ✓ App icons generated for Android, iOS, macOS, Windows, and Web

echo.
echo Step 3: Generating native splash screens...
call flutter pub run flutter_native_splash:create
echo ✓ Native splash screens generated

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Your app now has:
echo   ✓ Trellis logo as app icon
echo   ✓ Custom Flutter splash screen (3 seconds)
echo   ✓ Native Android splash screen
echo   ✓ Native iOS splash screen
echo.
echo You can now run: flutter run
echo.
pause
