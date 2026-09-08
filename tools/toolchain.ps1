param(
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-Executable {
    param(
        [string]$OverrideName,
        [string[]]$CommandNames,
        [string[]]$SearchRoots,
        [string]$Filter,
        [int]$Depth = 3
    )

    $override = [Environment]::GetEnvironmentVariable($OverrideName)
    if ($override) {
        if (-not (Test-Path -LiteralPath $override -PathType Leaf)) {
            throw "$OverrideName points to a missing file: $override"
        }
        return (Resolve-Path -LiteralPath $override).Path
    }

    foreach ($commandName in $CommandNames) {
        $command = Get-Command $commandName -CommandType Application -ErrorAction SilentlyContinue
        if ($command) {
            return $command.Source
        }
    }

    foreach ($root in $SearchRoots) {
        if (Test-Path -LiteralPath $root -PathType Container) {
            $matches = Get-ChildItem -LiteralPath $root -Filter $Filter -File -Recurse `
                -Depth $Depth -ErrorAction SilentlyContinue
            if ($matches) {
                return ($matches | Sort-Object FullName -Descending | Select-Object -First 1).FullName
            }
        }
    }
    return $null
}

function Add-Result {
    param(
        [System.Collections.Generic.List[object]]$Results,
        [string]$Tool,
        [string]$Status,
        [string]$Version,
        [string]$Path
    )
    $Results.Add([pscustomobject]@{
        Tool = $Tool
        Status = $Status
        Version = $Version
        Path = $Path
    })
}

$results = [System.Collections.Generic.List[object]]::new()
$failed = $false

$godot = Resolve-Executable -OverrideName 'GODOT' -CommandNames @('godot', 'godot4', 'Godot') `
    -SearchRoots @('C:\Tools\Godot', 'C:\Program Files\Godot', "$env:USERPROFILE\Downloads") `
    -Filter 'Godot*.exe' -Depth 4
if ($godot) {
    $godotVersion = (& $godot --version 2>$null | Select-Object -First 1).Trim()
    if ($godotVersion -match '\.mono\.') {
        Add-Result $results 'Godot' 'WRONG BUILD' $godotVersion $godot
        $failed = $true
    } elseif ($godotVersion -notmatch '^4\.') {
        Add-Result $results 'Godot' 'WRONG VERSION' $godotVersion $godot
        $failed = $true
    } else {
        Add-Result $results 'Godot' 'READY' $godotVersion $godot
    }
} else {
    Add-Result $results 'Godot' 'MISSING' '' ''
    $failed = $true
}

$blender = Resolve-Executable -OverrideName 'BLENDER' -CommandNames @('blender') `
    -SearchRoots @('C:\Program Files\Blender Foundation') -Filter 'blender.exe' -Depth 3
if ($blender) {
    $blenderVersion = (Get-Item -LiteralPath $blender).VersionInfo.ProductVersion
    Add-Result $results 'Blender' 'READY' $blenderVersion $blender
} else {
    Add-Result $results 'Blender' 'MISSING' '' ''
    $failed = $true
}

$krita = Resolve-Executable -OverrideName 'KRITA' -CommandNames @('krita') `
    -SearchRoots @('C:\Program Files\Krita (x64)', 'C:\Program Files\Krita') `
    -Filter 'krita.exe' -Depth 3
if ($krita) {
    $kritaVersion = (Get-Item -LiteralPath $krita).VersionInfo.ProductVersion
    Add-Result $results 'Krita' 'READY' $kritaVersion $krita
} else {
    Add-Result $results 'Krita' 'MISSING' '' ''
    $failed = $true
}

$gitLfs = Get-Command 'git-lfs' -CommandType Application -ErrorAction SilentlyContinue
if ($gitLfs) {
    $gitLfsVersion = (& $gitLfs.Source version | Select-Object -First 1).Trim()
    Add-Result $results 'Git LFS' 'READY' $gitLfsVersion $gitLfs.Source
} else {
    Add-Result $results 'Git LFS' 'MISSING' '' ''
    $failed = $true
}

$gitBash = Resolve-Executable -OverrideName 'GIT_BASH' -CommandNames @('bash') `
    -SearchRoots @('C:\Program Files\Git') -Filter 'bash.exe' -Depth 3
if ($gitBash) {
    $bashVersion = (& $gitBash --version | Select-Object -First 1).Trim()
    Add-Result $results 'Git Bash' 'READY' $bashVersion $gitBash
} else {
    Add-Result $results 'Git Bash' 'MISSING' '' ''
    $failed = $true
}

Add-Type -AssemblyName Microsoft.VisualBasic
$computerInfo = [Microsoft.VisualBasic.Devices.ComputerInfo]::new()
$ramGb = [math]::Round($computerInfo.TotalPhysicalMemory / 1GB, 1)

if ($Json) {
    [pscustomobject]@{
        Ready = -not $failed
        RamGb = $ramGb
        Tools = $results
    } | ConvertTo-Json -Depth 4
} else {
    $results | Format-Table -AutoSize
    "RAM: $ramGb GB"
    if ($failed) {
        'Toolchain is not ready.'
    } else {
        'Toolchain is ready.'
    }
}

exit $(if ($failed) { 1 } else { 0 })
