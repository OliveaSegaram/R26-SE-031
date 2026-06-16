@echo off
echo ============================================
echo  Task 02 — run in TWO separate terminals
echo ============================================
echo.
echo TERMINAL 1 - Backend (run this first):
echo   cd intervention-service
echo   run_backend.bat
echo.
echo TERMINAL 2 - Flutter UI:
echo   cd intervention-service\task_02\frontend
echo   run_task02.bat
echo.
echo Opening backend folder...
start cmd /k "cd /d %~dp0..\ && run_backend.bat"
timeout /t 3 /nobreak >nul
echo Opening Flutter UI...
start cmd /k "cd /d %~dp0frontend && run_task02.bat"
