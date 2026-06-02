@echo off
set ROOT_DIR=%~dp0..\..
set FLUTTER_BIN=%ROOT_DIR%\.flutter_sdk\flutter\bin\flutter.bat
if not exist "%FLUTTER_BIN%" (
  echo Flutter SDK lokal belum ditemukan di %FLUTTER_BIN%
  echo Jalankan: powershell -ExecutionPolicy Bypass -File .\tool\setup_flutter_sdk_windows.ps1
  exit /b 1
)
call "%FLUTTER_BIN%" %*
