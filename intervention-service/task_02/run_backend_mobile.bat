@echo off
REM Backend reachable from phones on the same Wi-Fi (LAN).
cd /d "%~dp0..\.."
echo Starting Task 02 backend for mobile (LAN)...
echo.
echo  On this PC:     http://127.0.0.1:8000
echo  On phone:       http://YOUR_PC_IP:8000
echo.
echo  Find YOUR_PC_IP: ipconfig  ^(look for IPv4 Address^)
echo.
echo  Then run Flutter with:
echo    flutter run --dart-define=API_BASE=http://YOUR_PC_IP:8000
echo.
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
