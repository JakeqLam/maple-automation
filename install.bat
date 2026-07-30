@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "INSTALLER=%ROOT%install_dependencies.ps1"

if not exist "%INSTALLER%" (
    echo.
    echo ERROR: Missing installer script:
    echo %INSTALLER%
    echo.
    pause
    exit /b 1
)

echo ============================================================
echo Maple Automation MVP dependency installer
echo ============================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%INSTALLER%"
set "RC=%ERRORLEVEL%"

echo.
if "%RC%"=="0" (
    echo Dependency installation and validation completed successfully.
) else (
    echo ERROR: Dependency installation failed with exit code %RC%.
    echo Review install_dependencies.log in this folder.
)
echo.
pause
exit /b %RC%
