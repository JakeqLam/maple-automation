[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogPath = Join-Path $Root 'install_dependencies.log'

function Write-InstallLog {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'OK')][string]$Level = 'INFO'
    )

    $line = '[{0}] [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8

    switch ($Level) {
        'OK'    { Write-Host $line -ForegroundColor Green }
        'WARN'  { Write-Host $line -ForegroundColor Yellow }
        'ERROR' { Write-Host $line -ForegroundColor Red }
        default { Write-Host $line }
    }
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Resolve-FirstExistingPath {
    param([Parameter(Mandatory = $true)][string[]]$Candidates)

    foreach ($candidate in $Candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    return $null
}

function Test-WinGetPackageInstalled {
    param(
        [Parameter(Mandatory = $true)][string]$Winget,
        [Parameter(Mandatory = $true)][string]$Id
    )

    $output = (& $Winget list --id $Id --exact --source winget --accept-source-agreements 2>$null | Out-String)
    return ($output -match [regex]::Escape($Id))
}

function Install-WinGetPackage {
    param(
        [Parameter(Mandatory = $true)][string]$Winget,
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$DisplayName
    )

    if (Test-WinGetPackageInstalled -Winget $Winget -Id $Id) {
        Write-InstallLog -Message "$DisplayName is already installed ($Id)." -Level OK
        return
    }

    Write-InstallLog -Message "Installing $DisplayName using WinGet package $Id..."

    & $Winget install `
        --id $Id `
        --exact `
        --source winget `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements `
        --disable-interactivity

    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0 -and -not (Test-WinGetPackageInstalled -Winget $Winget -Id $Id)) {
        throw "$DisplayName installation failed. WinGet exit code: $exitCode"
    }

    Write-InstallLog -Message "$DisplayName installed successfully." -Level OK
}

try {
    if (Test-Path -LiteralPath $LogPath) {
        Remove-Item -LiteralPath $LogPath -Force
    }

    Write-InstallLog -Message 'Maple Automation MVP dependency installation started.'
    Write-InstallLog -Message ("Installer directory: {0}" -f $Root)
    Write-InstallLog -Message ("PowerShell version: {0}" -f $PSVersionTable.PSVersion)

    if (-not (Test-IsAdministrator)) {
        Write-InstallLog -Message 'Administrator privileges are required. Requesting elevation.' -Level WARN

        $quotedScript = '"' + $MyInvocation.MyCommand.Path.Replace('"', '""') + '"'
        $process = Start-Process `
            -FilePath 'powershell.exe' `
            -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $quotedScript) `
            -Verb RunAs `
            -Wait `
            -PassThru

        exit $process.ExitCode
    }

    Write-InstallLog -Message 'Administrator privileges confirmed.' -Level OK

    $wingetCommand = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($null -eq $wingetCommand) {
        throw 'WinGet was not found. Install or repair Microsoft App Installer, then run install.bat again.'
    }

    $winget = $wingetCommand.Source
    Write-InstallLog -Message ("WinGet path: {0}" -f $winget)

    & $winget source update --disable-interactivity | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-InstallLog -Message ("WinGet source update returned exit code {0}; continuing with existing source data." -f $LASTEXITCODE) -Level WARN
    }

    Install-WinGetPackage -Winget $winget -Id 'AutoIt.AutoIt' -DisplayName 'AutoIt'
    Install-WinGetPackage -Winget $winget -Id 'UB-Mannheim.TesseractOCR' -DisplayName 'Tesseract OCR'

    $autoIt = Resolve-FirstExistingPath -Candidates @(
        (Join-Path ${env:ProgramFiles(x86)} 'AutoIt3\AutoIt3_x64.exe'),
        (Join-Path $env:ProgramFiles 'AutoIt3\AutoIt3_x64.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'AutoIt3\AutoIt3.exe'),
        (Join-Path $env:ProgramFiles 'AutoIt3\AutoIt3.exe')
    )

    if ($null -eq $autoIt) {
        throw 'AutoIt installation completed, but AutoIt3.exe was not found in a standard installation directory.'
    }
    Write-InstallLog -Message ("AutoIt verified: {0}" -f $autoIt) -Level OK

    $tesseract = Resolve-FirstExistingPath -Candidates @(
        (Join-Path $env:ProgramFiles 'Tesseract-OCR\tesseract.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Tesseract-OCR\tesseract.exe')
    )

    if ($null -eq $tesseract) {
        $pathCommand = Get-Command tesseract.exe -ErrorAction SilentlyContinue
        if ($null -ne $pathCommand) {
            $tesseract = $pathCommand.Source
        }
    }

    if ($null -eq $tesseract) {
        throw 'Tesseract installation completed, but tesseract.exe was not found.'
    }
    Write-InstallLog -Message ("Tesseract verified: {0}" -f $tesseract) -Level OK

    $engData = Join-Path (Split-Path -Parent $tesseract) 'tessdata\eng.traineddata'
    if (-not (Test-Path -LiteralPath $engData -PathType Leaf)) {
        throw "English Tesseract language data was not found: $engData"
    }
    Write-InstallLog -Message ("English OCR data verified: {0}" -f $engData) -Level OK

    $udfPath = Join-Path $Root 'ImageSearchDLL_UDF_Embedded.au3'
    if (Test-Path -LiteralPath $udfPath -PathType Leaf) {
        Write-InstallLog -Message ("ImageSearch UDF verified: {0}" -f $udfPath) -Level OK
    }
    else {
        Write-InstallLog -Message 'ImageSearchDLL_UDF_Embedded.au3 is not beside the application. It is a bundled project dependency, not a WinGet package; copy the known-working file here before launching.' -Level WARN
    }

    $mainScript = Get-ChildItem -LiteralPath $Root -Filter 'MapleAutomationMVP*_Admin.au3' -File |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    $au3Check = Resolve-FirstExistingPath -Candidates @(
        (Join-Path ${env:ProgramFiles(x86)} 'AutoIt3\Au3Check.exe'),
        (Join-Path $env:ProgramFiles 'AutoIt3\Au3Check.exe')
    )

    if ($null -ne $mainScript -and $null -ne $au3Check) {
        Write-InstallLog -Message ("Running AutoIt syntax validation: {0}" -f $mainScript.FullName)
        & $au3Check $mainScript.FullName
        if ($LASTEXITCODE -ne 0) {
            throw "Au3Check failed with exit code $LASTEXITCODE."
        }
        Write-InstallLog -Message 'AutoIt syntax validation passed.' -Level OK
    }
    else {
        Write-InstallLog -Message 'Skipped Au3Check because the application script or Au3Check.exe was not found.' -Level WARN
    }

    Write-InstallLog -Message 'All installable dependencies are ready.' -Level OK
    Write-Host ''
    Write-Host 'Next step: run Run-Maple-Automation-MVP-v0.2.1-Admin.cmd' -ForegroundColor Cyan
    exit 0
}
catch {
    Write-InstallLog -Message $_.Exception.Message -Level ERROR
    Write-InstallLog -Message 'Dependency installation failed.' -Level ERROR
    exit 1
}
