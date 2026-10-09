# Screen recorder for QA test runs (Windows, needs FFmpeg 8 or newer for window capture).
#   rec.ps1 start <test-name> [-Folder <name>] [-Window <exe>]   begin recording
#   rec.ps1 stop [-Folder <name>]                                end the current recording
#   rec.ps1 status [-Folder <name>]                              show whether one is running
# -Window claude (the default) records only the Claude window via Windows Graphics
#   Capture: it keeps recording while other windows cover it, but NOT while it is
#   minimized. Use -Window desktop to record the whole screen instead.
# Videos land in %USERPROFILE%\Videos\<Folder>\<timestamp>-<test-name>.mp4
param(
  [Parameter(Mandatory = $true)][ValidateSet('start', 'stop', 'status')][string]$Action,
  [string]$Name = 'test',
  # Subfolder of %USERPROFILE%\Videos; pass the same value to stop/status.
  [string]$Folder = 'qa-tests',
  [string]$Window = 'claude'
)

function Find-Ffmpeg {
  $cmd = Get-Command ffmpeg -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  foreach ($dir in @("$PSScriptRoot", 'C:\Tools\ffmpeg', 'C:\ffmpeg', "$env:LOCALAPPDATA\Microsoft\WinGet\Packages")) {
    if (Test-Path $dir) {
      $hit = Get-ChildItem $dir -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -First 1
      if ($hit) { return $hit.FullName }
    }
  }
  return $null
}

$outDir = Join-Path $env:USERPROFILE "Videos\$Folder"
$pidFile = Join-Path $outDir '.recording.pid'
New-Item -ItemType Directory -Force $outDir | Out-Null

function Get-Running {
  if (-not (Test-Path $pidFile)) { return $null }
  $id, $file = (Get-Content $pidFile) -split '\|', 2
  $p = Get-Process -Id $id -ErrorAction SilentlyContinue
  if ($p -and $p.ProcessName -eq 'ffmpeg') { return @{ Process = $p; File = $file } }
  return $null
}

switch ($Action) {
  'start' {
    if (Get-Running) { Write-Output "Already recording - stop it first."; exit 1 }
    $ffmpeg = Find-Ffmpeg
    if (-not $ffmpeg) { Write-Output 'ffmpeg not found - install it (see README) and try again.'; exit 1 }
    $safe = ($Name -replace '[^\w\-]+', '-').Trim('-')
    $file = Join-Path $outDir ("{0}-{1}.mp4" -f (Get-Date -Format 'yyyyMMdd-HHmmss'), $safe)
    # Fragmented MP4: the file stays playable even if the recording is cut off,
    # so stopping by terminating the process never leaves a corrupt video.
    $scale = 'scale=trunc(iw/2)*2:trunc(ih/2)*2'
    if ($Window -and $Window -ne 'desktop') {
      $src = @('-filter_complex', "`"gfxcapture=window_exe=(?i)$Window\.exe:max_framerate=12,hwdownload,format=bgra,format=yuv420p,$scale`"")
    } else {
      $src = @('-f', 'gdigrab', '-framerate', '12', '-draw_mouse', '1', '-i', 'desktop', '-vf', $scale)
    }
    $ffArgs = @('-hide_banner', '-loglevel', 'error') + $src + @(
      '-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '28', '-pix_fmt', 'yuv420p', '-g', '24',
      '-movflags', '+frag_keyframe+empty_moov+default_base_moof',
      "`"$file`""
    )
    $p = Start-Process -FilePath $ffmpeg -ArgumentList $ffArgs -WindowStyle Hidden -PassThru
    "$($p.Id)|$file" | Set-Content $pidFile
    Start-Sleep -Milliseconds 800
    if ($p.HasExited) { Write-Output "ffmpeg exited immediately - recording failed (window capture needs FFmpeg 8+)."; exit 1 }
    Write-Output "RECORDING -> $file"
  }
  'stop' {
    $r = Get-Running
    if (-not $r) { Write-Output 'No recording running.'; exit 0 }
    Stop-Process -Id $r.Process.Id
    Start-Sleep -Milliseconds 800
    Remove-Item $pidFile -ErrorAction SilentlyContinue
    $bytes = (Get-Item $r.File).Length
    $note = if ($bytes -lt 100KB) { ' - EMPTY: the window was probably minimized; rebuild with slideshows.ps1' } else { '' }
    Write-Output ("SAVED -> {0} ({1} MB){2}" -f $r.File, [math]::Round($bytes / 1MB, 1), $note)
  }
  'status' {
    $r = Get-Running
    if ($r) { Write-Output "Recording -> $($r.File)" } else { Write-Output 'Not recording.' }
  }
}
