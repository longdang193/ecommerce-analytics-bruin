@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "BRUIN_EXE=C:\Users\HOANG PHI LONG DANG\.local\bin\bruin.exe"
set "PSModulePath=C:\Program Files\WindowsPowerShell\Modules;C:\Windows\System32\WindowsPowerShell\v1.0\Modules"
set "PATH=C:\Users\HOANG PHI LONG DANG\.local\bin;%PATH%"

if not exist "%BRUIN_EXE%" (
  echo Bruin executable not found at "%BRUIN_EXE%".
  exit /b 1
)

pushd "%SCRIPT_DIR%" >nul
"%BRUIN_EXE%" %*
set "EXIT_CODE=%ERRORLEVEL%"
popd >nul

exit /b %EXIT_CODE%
