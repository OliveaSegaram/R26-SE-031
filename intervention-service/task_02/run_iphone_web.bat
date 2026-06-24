@echo off
REM Open Task 02 on iPhone Safari (no Mac needed). Same Wi-Fi as this PC.
cd /d "%~dp0frontend"
if not exist pubspec.yaml (
  echo ERROR: frontend folder not found.
  exit /b 1
)

echo ============================================
echo  Task 02 — iPhone test via Safari
echo ============================================
echo.
echo  1. In ANOTHER terminal, start backend:
echo       task_02\run_backend_mobile.bat
echo.
echo  2. Find PC IP:  ipconfig
echo     Use **Wi-Fi** IPv4 (e.g. 192.168.x.x)
echo     Do NOT use vEthernet / 172.22.x.x — phone cannot reach it.
echo.
set /p PC_IP=Enter your PC IPv4 (e.g. 192.168.1.10): 
if "%PC_IP%"=="" (
  echo No IP entered.
  exit /b 1
)

echo.
echo  3. On iPhone Safari, open:
echo       http://%PC_IP%:8080
echo.
echo  4. Optional: Share - Add to Home Screen
echo.
flutter pub get
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080 --dart-define=API_BASE=http://%PC_IP%:8000
