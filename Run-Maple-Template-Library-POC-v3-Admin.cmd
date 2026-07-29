@echo off
setlocal

set "ROOT=C:\Users\Jake Lam\code\maple-automation"
set "SCRIPT=%ROOT%\MapleTemplateLibraryPOC_v3_Admin.au3"

if not exist "%SCRIPT%" (
    echo.
    echo ERROR: The Template Library POC v3 script was not found:
    echo %SCRIPT%
    echo.
    echo Extract this entire bundle directly into:
    echo %ROOT%
    echo.
    pause
    exit /b 1
)

if not exist "%ROOT%\ImageSearchDLL_UDF_Embedded.au3" (
    echo.
    echo ERROR: Missing existing ImageSearch UDF:
    echo %ROOT%\ImageSearchDLL_UDF_Embedded.au3
    echo.
    pause
    exit /b 1
)

if not exist "%ROOT%\data\player" mkdir "%ROOT%\data\player"
if not exist "%ROOT%\data\target" mkdir "%ROOT%\data\target"

set "AUTOIT=%ProgramFiles(x86)%\AutoIt3\AutoIt3_x64.exe"
if not exist "%AUTOIT%" set "AUTOIT=%ProgramFiles%\AutoIt3\AutoIt3_x64.exe"
if not exist "%AUTOIT%" set "AUTOIT=%ProgramFiles(x86)%\AutoIt3\AutoIt3.exe"
if not exist "%AUTOIT%" set "AUTOIT=%ProgramFiles%\AutoIt3\AutoIt3.exe"

if not exist "%AUTOIT%" (
    echo.
    echo ERROR: AutoIt was not found in a standard installation folder.
    echo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "Start-Process -FilePath '%AUTOIT%' -ArgumentList '\"%SCRIPT%\"' -WorkingDirectory '%ROOT%' -Verb RunAs"

if errorlevel 1 (
    echo.
    echo Failed to request administrator elevation.
    echo.
    pause
    exit /b 1
)

endlocal
