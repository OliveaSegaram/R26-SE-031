@echo off
cd /d "%~dp0"
if not exist pubspec.yaml (
  echo ERROR: Run from task_02\frontend
  exit /b 1
)
echo Task 02 — Android
echo.
echo 1. Start backend (LAN) in another terminal:
echo    task_02\run_backend_mobile.bat
echo.
echo 2. For a REAL phone, set your PC IP:
echo    set API=http://192.168.1.10:8000
echo    flutter run --dart-define=API_BASE=%API%
echo.
echo 3. For Android EMULATOR only (default 10.0.2.2):
echo    flutter run -d android
echo.
flutter pub get
if "%API_BASE%"=="" (
  flutter run -d android
) else (
  flutter run -d android --dart-define=API_BASE=%API_BASE%
)
