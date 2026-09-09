param(
    [string[]]$Phases = @('environment', 'characters', 'exploration', 'incident', 'narrative', 'polish')
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$godotCandidates = Get-ChildItem -LiteralPath 'C:\Tools\Godot' -Filter 'Godot*.exe' -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notmatch 'console|mono' } |
    Sort-Object FullName

if (-not $godotCandidates) {
    throw 'Godot standard build not found under C:\Tools\Godot.'
}

$godot = $godotCandidates[-1].FullName
$reviewDirectory = Join-Path $repoRoot 'art\review'
New-Item -ItemType Directory -Force -Path $reviewDirectory | Out-Null

Push-Location $repoRoot
try {
    foreach ($phase in $Phases) {
        Write-Host "Capturing Junction view: $phase"
        $stdoutPath = Join-Path ([IO.Path]::GetTempPath()) "etherbound-$phase-stdout.log"
        $stderrPath = Join-Path ([IO.Path]::GetTempPath()) "etherbound-$phase-stderr.log"
        Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
        $process = Start-Process -FilePath $godot `
            -ArgumentList @('--path', 'game', '--', "--capture=$phase") `
            -WorkingDirectory $repoRoot `
            -WindowStyle Hidden `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath `
            -PassThru `
            -Wait
        $runtimeOutput = ((Get-Content -Raw -LiteralPath $stdoutPath -ErrorAction SilentlyContinue) + "`n" +
            (Get-Content -Raw -LiteralPath $stderrPath -ErrorAction SilentlyContinue))
        if ($process.ExitCode -ne 0) {
            throw "Godot capture failed for phase '$phase' with exit code $($process.ExitCode)."
        }
        if ($runtimeOutput -match 'SCRIPT ERROR|Parse Error|Invalid call|Invalid assignment') {
            throw "Godot reported a runtime script error during '$phase':`n$runtimeOutput"
        }
        $expected = Join-Path $reviewDirectory "junction_$phase.png"
        if (-not (Test-Path -LiteralPath $expected)) {
            throw "Godot did not create $expected."
        }
        Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    }
}
finally {
    Pop-Location
}
