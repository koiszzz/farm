param(
    [ValidateSet('forward_plus', 'gl_compatibility')]
    [string]$RenderingMethod = 'forward_plus'
)

$ErrorActionPreference = 'Stop'

$godotPath = 'C:\workspace\tools\godot\Godot_v4.7.1-stable_win64_console.exe'
$projectPath = 'E:\project\farm'
$loadingPath = Join-Path $projectPath 'design\qa\2026-09-24\loading'
$sampleCount = 5
$samples = [System.Collections.Generic.List[object]]::new()
$previousSuffix = [Environment]::GetEnvironmentVariable('FARM_COLD_START_SAMPLE', 'Process')

try {
    for ($index = 1; $index -le $sampleCount; $index++) {
        $suffix = '{0}-{1:D2}' -f $RenderingMethod, $index
        $profilePath = Join-Path $loadingPath "cold-start-profile-$suffix.json"
        $markerPath = Join-Path $loadingPath "cold-start-profile-$suffix.done"
        Remove-Item -LiteralPath $profilePath, $markerPath -Force -ErrorAction SilentlyContinue
        [Environment]::SetEnvironmentVariable('FARM_COLD_START_SAMPLE', $suffix, 'Process')

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $process = Start-Process -FilePath $godotPath -ArgumentList @(
            '--path', $projectPath,
            '--rendering-method', $RenderingMethod,
            '--script', 'scripts/cold_start_profile.gd'
        ) -PassThru -WindowStyle Hidden

        while (-not (Test-Path -LiteralPath $markerPath) -and -not $process.HasExited) {
            Start-Sleep -Milliseconds 20
        }
        $launchToFirstFrameMs = $stopwatch.Elapsed.TotalMilliseconds
        $profile = if (Test-Path -LiteralPath $profilePath) {
            Get-Content -LiteralPath $profilePath -Raw | ConvertFrom-Json
        } else {
            $null
        }

        $process.WaitForExit()
        $stopwatch.Stop()
        $samples.Add([pscustomobject]@{
            iteration = $index
            launch_to_first_frame_ms = [Math]::Round($launchToFirstFrameMs, 1)
            launch_to_process_exit_ms = [Math]::Round($stopwatch.Elapsed.TotalMilliseconds, 1)
            exit_code = $process.ExitCode
            profile = $profile
        })
        Write-Output "cold-start sample ${index}: launch-to-frame=$([Math]::Round($launchToFirstFrameMs, 1))ms, exit=$($process.ExitCode)"
    }
} finally {
    [Environment]::SetEnvironmentVariable('FARM_COLD_START_SAMPLE', $previousSuffix, 'Process')
}

$batch = [pscustomobject]@{
    machine = '13th Gen Intel Core i7-13700H / NVIDIA RTX 3050 Laptop GPU'
    engine = 'Godot 4.7.1'
    renderer = $RenderingMethod
    sample_count = $samples.Count
    samples = $samples
}
$outputPath = Join-Path $loadingPath "cold-start-process-profile-$RenderingMethod.json"
$batch | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $outputPath -Encoding utf8
for ($index = 1; $index -le $sampleCount; $index++) {
    $suffix = '{0}-{1:D2}' -f $RenderingMethod, $index
    $markerPath = Join-Path $loadingPath "cold-start-profile-$suffix.done"
    Remove-Item -LiteralPath $markerPath -Force -ErrorAction SilentlyContinue
}
Write-Output "saved $outputPath"
