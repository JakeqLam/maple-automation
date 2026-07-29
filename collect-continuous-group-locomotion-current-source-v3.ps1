Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$ProjectRoot = "C:\Users\Jake Lam\dnd-workspace\dnd-prototype"
$DownloadsRoot = "C:\Users\Jake Lam\Downloads"
$PacketPrefix = "continuous-group-locomotion-current-source"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$PacketName = "$PacketPrefix-$Timestamp"
$StageRoot = Join-Path $DownloadsRoot $PacketName
$ZipPath = Join-Path $DownloadsRoot ($PacketName + ".zip")
$ReportsRoot = Join-Path $StageRoot "_reports"

$AllowedExtensions = @(
    ".gd",
    ".uid",
    ".tscn",
    ".tres",
    ".godot",
    ".md",
    ".txt",
    ".json",
    ".csv",
    ".cfg"
)

$RequiredSeedFiles = @(
    "project.godot",
    "docs/architecture/project_context.md"
)

$RequiredDirectories = @(
    "scripts/input",
    "scripts/framework",
    "scripts/simulation",
    "scripts/presentation",
    "scripts/environment",
    "scenes/battle",
    "scenes/units",
    "data/units",
    "data/objects",
    "data/maps",
    "docs/architecture"
)

$OptionalDirectories = @(
    "scripts/tests",
    "tests",
    "scenes/environment",
    "scenes/objects",
    "data/terrain",
    "data/formations"
)

function Normalize-RelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $Normalized = $Path.Replace("\", "/").Trim()
    while ($Normalized.StartsWith("./", [System.StringComparison]::Ordinal)) {
        $Normalized = $Normalized.Substring(2)
    }
    $Normalized = $Normalized.TrimStart("/".ToCharArray())

    if ([string]::IsNullOrWhiteSpace($Normalized)) {
        throw "A collected project-relative path was empty."
    }

    if ([System.IO.Path]::IsPathRooted($Normalized)) {
        throw "A collected path was unexpectedly absolute: $Normalized"
    }

    $Segments = @($Normalized.Split("/".ToCharArray(), [System.StringSplitOptions]::RemoveEmptyEntries))
    if ($Segments -contains "..") {
        throw "A collected path attempted to escape the project root: $Normalized"
    }

    return ($Segments -join "/")
}

function Test-AllowedSourcePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $Extension = [System.IO.Path]::GetExtension($RelativePath).ToLowerInvariant()
    return ($AllowedExtensions -contains $Extension)
}

function Get-ProjectFullPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $NativeRelativePath = $RelativePath.Replace("/", [System.IO.Path]::DirectorySeparatorChar)
    return (Join-Path $ProjectRoot $NativeRelativePath)
}

function Get-ProjectRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FullPath
    )

    $ProjectPrefix = $ProjectRoot.TrimEnd("\".ToCharArray()) + "\"
    if (-not $FullPath.StartsWith($ProjectPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "A discovered file is outside the canonical project root: $FullPath"
    }

    return (Normalize-RelativePath -Path $FullPath.Substring($ProjectPrefix.Length))
}

function Invoke-GitText {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $Output = @(& git -C $ProjectRoot @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        $Rendered = ($Output -join [Environment]::NewLine)
        throw "Git command failed: git -C `"$ProjectRoot`" $($Arguments -join ' ')`n$Rendered"
    }

    return $Output
}

$QueuedPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$CollectedPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$PendingPaths = [System.Collections.Generic.Queue[string]]::new()
$UnresolvedPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$ManifestRows = [System.Collections.Generic.List[object]]::new()

function Add-PendingPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $Normalized = Normalize-RelativePath -Path $RelativePath
    if (-not (Test-AllowedSourcePath -RelativePath $Normalized)) {
        return
    }

    if ($QueuedPaths.Add($Normalized)) {
        $PendingPaths.Enqueue($Normalized)
    }

    if ($Normalized.EndsWith(".gd", [System.StringComparison]::OrdinalIgnoreCase)) {
        $UidRelativePath = $Normalized + ".uid"
        $UidFullPath = Get-ProjectFullPath -RelativePath $UidRelativePath
        if ((Test-Path -LiteralPath $UidFullPath -PathType Leaf) -and $QueuedPaths.Add($UidRelativePath)) {
            $PendingPaths.Enqueue($UidRelativePath)
        }
    }
}

function Add-DirectorySources {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativeDirectory,

        [Parameter(Mandatory = $true)]
        [bool]$Required
    )

    $NormalizedDirectory = Normalize-RelativePath -Path $RelativeDirectory
    $FullDirectory = Get-ProjectFullPath -RelativePath $NormalizedDirectory

    if (-not (Test-Path -LiteralPath $FullDirectory -PathType Container)) {
        if ($Required) {
            throw "Required collector source directory is missing:`n$NormalizedDirectory"
        }
        return
    }

    $Files = @(Get-ChildItem -LiteralPath $FullDirectory -Recurse -File | Sort-Object -Property FullName)
    foreach ($File in $Files) {
        $RelativePath = Get-ProjectRelativePath -FullPath $File.FullName
        if (Test-AllowedSourcePath -RelativePath $RelativePath) {
            Add-PendingPath -RelativePath $RelativePath
        }
    }
}

function Add-TransitiveReferences {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceFullPath
    )

    $Content = Get-Content -LiteralPath $SourceFullPath -Raw
    $Matches = [regex]::Matches($Content, 'res://(?<path>[^"''\s\)\]\},;]+)')

    foreach ($Match in $Matches) {
        $ReferencedPath = [string]$Match.Groups["path"].Value

        $DoubleColonIndex = $ReferencedPath.IndexOf("::", [System.StringComparison]::Ordinal)
        if ($DoubleColonIndex -ge 0) {
            $ReferencedPath = $ReferencedPath.Substring(0, $DoubleColonIndex)
        }

        $FragmentIndex = $ReferencedPath.IndexOf("#", [System.StringComparison]::Ordinal)
        if ($FragmentIndex -ge 0) {
            $ReferencedPath = $ReferencedPath.Substring(0, $FragmentIndex)
        }

        $QueryIndex = $ReferencedPath.IndexOf("?", [System.StringComparison]::Ordinal)
        if ($QueryIndex -ge 0) {
            $ReferencedPath = $ReferencedPath.Substring(0, $QueryIndex)
        }

        $ReferencedPath = $ReferencedPath.TrimEnd(".".ToCharArray())
        if ([string]::IsNullOrWhiteSpace($ReferencedPath)) {
            continue
        }

        try {
            $NormalizedReference = Normalize-RelativePath -Path $ReferencedPath
        }
        catch {
            continue
        }

        if (-not (Test-AllowedSourcePath -RelativePath $NormalizedReference)) {
            continue
        }

        $ReferencedFullPath = Get-ProjectFullPath -RelativePath $NormalizedReference
        if (Test-Path -LiteralPath $ReferencedFullPath -PathType Leaf) {
            Add-PendingPath -RelativePath $NormalizedReference
        }
        else {
            [void]$UnresolvedPaths.Add($NormalizedReference)
        }
    }
}

function Write-Utf8Lines {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LiteralPath,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Lines
    )

    $Utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllLines($LiteralPath, $Lines, $Utf8WithoutBom)
}

try {
    if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
        throw "Canonical Godot project root is missing:`n$ProjectRoot"
    }

    if (-not (Test-Path -LiteralPath $DownloadsRoot -PathType Container)) {
        throw "Hard-coded Downloads directory is missing:`n$DownloadsRoot"
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "Git is not available on PATH."
    }

    $InsideWorkTree = ((Invoke-GitText -Arguments @("rev-parse", "--is-inside-work-tree")) -join "").Trim()
    if ($InsideWorkTree -ne "true") {
        throw "The canonical project root is not a Git work tree:`n$ProjectRoot"
    }

    $GitBranch = ((Invoke-GitText -Arguments @("branch", "--show-current")) -join "").Trim()
    if ([string]::IsNullOrWhiteSpace($GitBranch)) {
        $GitBranch = "(detached HEAD)"
    }

    $GitCommit = ((Invoke-GitText -Arguments @("rev-parse", "HEAD")) -join "").Trim()
    $GitStatusLines = @(Invoke-GitText -Arguments @("status", "--porcelain=v1"))
    $GitDiffSummaryLines = @(Invoke-GitText -Arguments @("diff", "--stat", "HEAD"))

    if ($GitStatusLines.Count -gt 0) {
        $RenderedStatus = $GitStatusLines -join [Environment]::NewLine
        throw @"
The working tree is not clean.

Current Git status:
$RenderedStatus

Checkpoint the verified slice first:
cd '$ProjectRoot'; git add .; git commit -m "checkpoint: continuous group locomotion baseline"
"@
    }

    foreach ($SeedFile in $RequiredSeedFiles) {
        $NormalizedSeed = Normalize-RelativePath -Path $SeedFile
        $SeedFullPath = Get-ProjectFullPath -RelativePath $NormalizedSeed
        if (-not (Test-Path -LiteralPath $SeedFullPath -PathType Leaf)) {
            throw "Required collector seed file is missing:`n$NormalizedSeed"
        }
        Add-PendingPath -RelativePath $NormalizedSeed
    }

    foreach ($RequiredDirectory in $RequiredDirectories) {
        Add-DirectorySources -RelativeDirectory $RequiredDirectory -Required $true
    }

    foreach ($OptionalDirectory in $OptionalDirectories) {
        Add-DirectorySources -RelativeDirectory $OptionalDirectory -Required $false
    }

    if (Test-Path -LiteralPath $StageRoot) {
        Remove-Item -LiteralPath $StageRoot -Recurse -Force
    }
    if (Test-Path -LiteralPath $ZipPath) {
        Remove-Item -LiteralPath $ZipPath -Force
    }

    New-Item -ItemType Directory -Path $ReportsRoot -Force | Out-Null

    while ($PendingPaths.Count -gt 0) {
        $RelativePath = $PendingPaths.Dequeue()
        if (-not $CollectedPaths.Add($RelativePath)) {
            continue
        }

        $SourceFullPath = Get-ProjectFullPath -RelativePath $RelativePath
        if (-not (Test-Path -LiteralPath $SourceFullPath -PathType Leaf)) {
            [void]$UnresolvedPaths.Add($RelativePath)
            continue
        }

        $DestinationFullPath = Join-Path $StageRoot $RelativePath.Replace("/", [System.IO.Path]::DirectorySeparatorChar)
        $DestinationDirectory = Split-Path -Parent $DestinationFullPath
        if (-not (Test-Path -LiteralPath $DestinationDirectory -PathType Container)) {
            New-Item -ItemType Directory -Path $DestinationDirectory -Force | Out-Null
        }

        $SourceFile = Get-Item -LiteralPath $SourceFullPath
        $SourceHash = (Get-FileHash -LiteralPath $SourceFullPath -Algorithm SHA256).Hash.ToLowerInvariant()
        Copy-Item -LiteralPath $SourceFullPath -Destination $DestinationFullPath -Force

        $DestinationFile = Get-Item -LiteralPath $DestinationFullPath
        $DestinationHash = (Get-FileHash -LiteralPath $DestinationFullPath -Algorithm SHA256).Hash.ToLowerInvariant()

        if (($SourceFile.Length -ne $DestinationFile.Length) -or ($SourceHash -ne $DestinationHash)) {
            throw "Collected-file copy validation failed:`n$RelativePath"
        }

        $ManifestRows.Add([pscustomobject][ordered]@{
            relative_path = $RelativePath
            size_bytes = [int64]$SourceFile.Length
            sha256 = $SourceHash
            source_full_path = $SourceFullPath
        })

        Add-TransitiveReferences -SourceFullPath $SourceFullPath
    }

    $SortedManifestRows = @($ManifestRows | Sort-Object -Property relative_path)
    if ($SortedManifestRows.Count -eq 0) {
        throw "The collector found no source files."
    }

    foreach ($Row in $SortedManifestRows) {
        $SourceFullPath = [string]$Row.source_full_path
        $RelativePath = [string]$Row.relative_path
        $DestinationFullPath = Join-Path $StageRoot $RelativePath.Replace("/", [System.IO.Path]::DirectorySeparatorChar)

        if (-not (Test-Path -LiteralPath $SourceFullPath -PathType Leaf)) {
            throw "A canonical source file disappeared during collection:`n$RelativePath"
        }
        if (-not (Test-Path -LiteralPath $DestinationFullPath -PathType Leaf)) {
            throw "A staged source file disappeared during collection:`n$RelativePath"
        }

        $CurrentSourceFile = Get-Item -LiteralPath $SourceFullPath
        $CurrentDestinationFile = Get-Item -LiteralPath $DestinationFullPath
        $ExpectedSize = [int64]$Row.size_bytes
        $ExpectedHash = [string]$Row.sha256
        $CurrentSourceHash = (Get-FileHash -LiteralPath $SourceFullPath -Algorithm SHA256).Hash.ToLowerInvariant()
        $CurrentDestinationHash = (Get-FileHash -LiteralPath $DestinationFullPath -Algorithm SHA256).Hash.ToLowerInvariant()

        if (($CurrentSourceFile.Length -ne $ExpectedSize) -or ($CurrentSourceHash -ne $ExpectedHash)) {
            throw "Canonical source changed during collection:`n$RelativePath"
        }
        if (($CurrentDestinationFile.Length -ne $ExpectedSize) -or ($CurrentDestinationHash -ne $ExpectedHash)) {
            throw "Staged source validation failed:`n$RelativePath"
        }
    }

    $ManifestPath = Join-Path $ReportsRoot "manifest.csv"
    $ManifestExportRows = @($SortedManifestRows | Select-Object relative_path, size_bytes, sha256)
    $ManifestExportRows | Export-Csv -LiteralPath $ManifestPath -NoTypeInformation -Encoding UTF8

    $SourceTreePath = Join-Path $ReportsRoot "source-tree.txt"
    $SourceTreeLines = @($SortedManifestRows | ForEach-Object { [string]$_.relative_path })
    Write-Utf8Lines -LiteralPath $SourceTreePath -Lines $SourceTreeLines

    $UnresolvedPath = Join-Path $ReportsRoot "unresolved-references.txt"
    $SortedUnresolved = @($UnresolvedPaths | Sort-Object)
    if ($SortedUnresolved.Count -eq 0) {
        Write-Utf8Lines -LiteralPath $UnresolvedPath -Lines @("none")
    }
    else {
        Write-Utf8Lines -LiteralPath $UnresolvedPath -Lines $SortedUnresolved
    }

    $TotalBytes = [int64](($SortedManifestRows | Measure-Object -Property size_bytes -Sum).Sum)
    $GitStatusText = "clean"
    $GitDiffSummaryText = if ($GitDiffSummaryLines.Count -eq 0) { "none" } else { $GitDiffSummaryLines -join [Environment]::NewLine }
    $GeneratedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss zzz")

    $CollectorReportLines = @(
        "DND-GAME CONTINUOUS GROUP LOCOMOTION - CURRENT SOURCE PACKET",
        "",
        "CANONICAL STATUS",
        "Treat this ZIP as the current canonical source packet for the Continuous Group Locomotion POC.",
        "Runtime screenshots and logs remain verification evidence.",
        "The failed free-form Squad Flow v1 implementation is historical evidence only and must not be restored.",
        "The current Friendly Pass-Through / Squad Movement v2 slice is not runtime verified as the final group-movement architecture.",
        "",
        "GENERATION",
        "Generated: $GeneratedAt",
        "Project root: $ProjectRoot",
        "Output ZIP: $ZipPath",
        "Git branch: $GitBranch",
        "Git commit: $GitCommit",
        "Git status: $GitStatusText",
        "Git diff summary: $GitDiffSummaryText",
        "Collected project files: $($SortedManifestRows.Count)",
        "Uncompressed project-source bytes: $TotalBytes",
        "Unresolved transitive references: $($SortedUnresolved.Count)",
        "",
        "COLLECTION STRATEGY",
        "1. Explicit mandatory seed files.",
        "2. Focused required source directories.",
        "3. Recursive text-based res:// dependency discovery.",
        "4. Matching .gd.uid collection.",
        "5. Per-file SHA-256 and size validation before ZIP creation.",
        "",
        "REQUESTED INVESTIGATION",
        "Create a separate Continuous Group Locomotion domain for player-issued multi-unit ground movement.",
        "Review the current command, pathfinding, simulation, occupancy, presentation, environment-blocker, interruption, and diagnostics architecture before implementation.",
        "",
        "FIRST POC BOUNDARY",
        "Include one authoritative squad-anchor route, authoritative travel duration/progress, slowest-member speed, smooth simultaneous presentation, soft allied avoidance, latest-click-wins replacement, deterministic arrival materialization, combat/order interruption materialization, and runtime diagnostics.",
        "Defer enemy squad locomotion, combat while continuously travelling, attack-move, authored formation templates, right-drag frontage/facing, siege equipment, single-unit tactical movement replacement, and broad NavigationServer authority.",
        "",
        "PRESERVATION REQUIREMENTS",
        "Simulation remains authoritative.",
        "Hover remains tile-highlight-only with zero pathfinding.",
        "Committed multi-unit ground movement calculates one shared squad-anchor route.",
        "Single-unit movement and all tactical materialization remain tile-authoritative.",
        "Walls, terrain boundaries, and closed doors remain hard route obstacles.",
        "Allied member visuals may use presentation-only soft avoidance and may not alter gameplay timing.",
        "No two units may own the same tactical tile after materialization.",
        "Do not restore Squad Flow v1.",
        "Do not launch Godot automatically.",
        "",
        "IMPLEMENTATION REVIEW REQUIREMENTS",
        "Validate every manifest entry after upload.",
        "Inspect source-tree.txt and unresolved-references.txt.",
        "Map exact classes, scenes, resources, commands, signals, events, tests, and ownership boundaries.",
        "Identify expected changed files and baseline hashes before authoring the installer.",
        "Produce no implementation payload until the source review is complete."
    )

    $CollectorReportPath = Join-Path $ReportsRoot "collector-report.txt"
    Write-Utf8Lines -LiteralPath $CollectorReportPath -Lines $CollectorReportLines

    foreach ($Row in $SortedManifestRows) {
        $RelativePath = [string]$Row.relative_path
        $DestinationFullPath = Join-Path $StageRoot $RelativePath.Replace("/", [System.IO.Path]::DirectorySeparatorChar)
        $ExpectedHash = [string]$Row.sha256
        $ExpectedSize = [int64]$Row.size_bytes
        $ActualFile = Get-Item -LiteralPath $DestinationFullPath
        $ActualHash = (Get-FileHash -LiteralPath $DestinationFullPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if (($ActualFile.Length -ne $ExpectedSize) -or ($ActualHash -ne $ExpectedHash)) {
            throw "Final pre-ZIP manifest validation failed:`n$RelativePath"
        }
    }

    Compress-Archive -Path (Join-Path $StageRoot "*") -DestinationPath $ZipPath -CompressionLevel Optimal -Force

    if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
        throw "ZIP creation did not produce the expected file:`n$ZipPath"
    }

    $ZipFile = Get-Item -LiteralPath $ZipPath
    if ($ZipFile.Length -le 0) {
        throw "ZIP creation produced an empty file:`n$ZipPath"
    }

    $ZipHash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    Remove-Item -LiteralPath $StageRoot -Recurse -Force

    Write-Host ""
    Write-Host "CONTINUOUS GROUP LOCOMOTION SOURCE PACKET: READY" -ForegroundColor Green
    Write-Host "ZIP:      $ZipPath"
    Write-Host "Files:    $($SortedManifestRows.Count)"
    Write-Host "Bytes:    $TotalBytes"
    Write-Host "ZIP size: $($ZipFile.Length)"
    Write-Host "SHA-256:  $ZipHash"
    if ($SortedUnresolved.Count -gt 0) {
        Write-Host "Warnings: $($SortedUnresolved.Count) unresolved text-source reference(s); see _reports/unresolved-references.txt" -ForegroundColor Yellow
    }
    Write-Host "Godot was not launched."
}
catch {
    if (Test-Path -LiteralPath $ZipPath) {
        Remove-Item -LiteralPath $ZipPath -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $StageRoot) {
        Remove-Item -LiteralPath $StageRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host ""
    Write-Host "CONTINUOUS GROUP LOCOMOTION SOURCE PACKET: FAILED" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "The project was not modified. Godot was not launched."
    exit 1
}
