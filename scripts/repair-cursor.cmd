@echo off
REM Double-click this to repair Cursor on Windows.
cd /d "%~dp0\.."
echo Quitting Cursor and running full safe repair...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0repair-cursor.ps1"
echo.
pause
