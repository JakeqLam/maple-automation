@echo off
setlocal

set "SCRIPT=C:\Users\Jake Lam\code\maple-automation\ImageSearchDLL_UDF_v3.5.1\ImageSearchDLL_UDF\ImageSearchSmokeTest_GUI_Admin_MapleSaga_v2.au3"

if not exist "%SCRIPT%" (
    echo.
    echo ERROR: The AutoIt script was not found:
    echo %SCRIPT%
    echo.
    echo Place ImageSearchSmokeTest_GUI_Admin_MapleSaga_v2.au3 in the ImageSearchDLL_UDF folder.
    echo.
    pause
    exit /b 1
)

set "AUTOIT=%ProgramFiles(x86)%\AutoIt3\AutoIt3.exe"
if not exist "%AUTOIT%" set "AUTOIT=%ProgramFiles%\AutoIt3\AutoIt3.exe"

if not exist "%AUTOIT%" (
    echo.
    echo ERROR: AutoIt3.exe was not found in either standard install location.
    echo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "Start-Process -FilePath '%AUTOIT%' -ArgumentList '\"%SCRIPT%\"' -Verb RunAs"

if errorlevel 1 (
    echo.
    echo Failed to request administrator elevation.
    echo.
    pause
    exit /b 1
)

endlocal
