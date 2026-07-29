@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "SCRIPT=%ROOT%\MapleAutomationMVP_v0.2.0_Admin.au3"

if not exist "%SCRIPT%" (
    echo.
    echo ERROR: The combined Maple Automation MVP script was not found:
    echo %SCRIPT%
    echo.
    pause
    exit /b 1
)

if not exist "%ROOT%\ImageSearchDLL_UDF_Embedded.au3" (
    echo.
    echo ERROR: Missing required ImageSearch UDF:
    echo %ROOT%\ImageSearchDLL_UDF_Embedded.au3
    echo.
    echo Copy your existing working UDF beside this launcher and script.
    echo.
    pause
    exit /b 1
)

if not exist "%ROOT%\data\player" mkdir "%ROOT%\data\player"
if not exist "%ROOT%\data\target" mkdir "%ROOT%\data\target"
if not exist "%ROOT%\debug\ocr_temp" mkdir "%ROOT%\debug\ocr_temp"

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

set "AU3CHECK=%ProgramFiles(x86)%\AutoIt3\Au3Check.exe"
if not exist "%AU3CHECK%" set "AU3CHECK=%ProgramFiles%\AutoIt3\Au3Check.exe"
if exist "%AU3CHECK%" (
    echo Checking AutoIt syntax...
    "%AU3CHECK%" "%SCRIPT%"
    if errorlevel 1 (
        echo.
        echo ERROR: AutoIt syntax validation failed. Review the messages above.
        echo.
        pause
        exit /b 1
    )
)

pushd "%ROOT%"
"%AUTOIT%" "%SCRIPT%"
set "RC=%ERRORLEVEL%"
popd

if not "%RC%"=="0" (
    echo.
    echo AutoIt exited with code %RC%.
    echo Check: %ROOT%\debug\MapleAutomationMVP.log
    echo.
    pause
)

exit /b %RC%
