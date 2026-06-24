@echo off
REM Task 02 backend — localhost only (Windows desktop / emulator on same PC).
cd /d "%~dp0"
echo Starting Task 02 backend at http://127.0.0.1:8000
python -m uvicorn main:app --reload --port 8000 --reload-dir backend
