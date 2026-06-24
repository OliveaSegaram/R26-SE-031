@echo off
cd /d "%~dp0"
if not exist pubspec.yaml (
  echo ERROR: Run this from task_02\frontend folder.
  echo   cd intervention-service\task_02\frontend
  exit /b 1
)
echo Task 02 Flutter UI
echo Backend must already run in another terminal:
echo   cd intervention-service
echo   run_backend.bat
echo.
flutter pub get
if "%1"=="chrome" (
  flutter run -d chrome
) else (
  flutter run -d windows
)
