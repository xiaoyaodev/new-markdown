@echo off
cd /d %~dp0
if not exist md-backup.reg (
  echo md-backup.reg not found in this folder - nothing was changed.
  echo Put this file in the same folder where ShortenMDName.bat was run, then try again.
  pause
  exit /b 1
)
reg import md-backup.reg
reg delete "HKCU\Software\Classes\UserMarkdownFile" /f >nul 2>&1
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
echo Restored to the state before the script ran.
pause
