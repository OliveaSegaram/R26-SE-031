@echo off
echo ============================================
echo  Task 02 — run in TWO separate terminals
echo ============================================
echo.
echo TERMINAL 1 - Backend:
echo   task_02\run_backend.bat
echo.
echo TERMINAL 2 - Flutter UI:
echo   task_02\frontend\run_task02.bat
echo.
start cmd /k "cd /d %~dp0 && run_backend.bat"
timeout /t 3 /nobreak >nul
start cmd /k "cd /d %~dp0frontend && run_task02.bat"
