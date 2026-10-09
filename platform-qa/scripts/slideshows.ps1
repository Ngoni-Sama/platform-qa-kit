# Rebuild empty recordings (Claude window was minimized) as slideshows from the
# browser screenshots taken during that section, matched by file time.
#   slideshows.ps1 -Folder <Videos subfolder> -ShotsDir <folder holding the screenshot .jpg files>
# ShotsDir is the folder shown in each screenshot result's "source:" path
# (…\.claude\projects\<project>\<session>\tool-results).
param(
  [Parameter(Mandatory = $true)][string]$Folder,
  [Parameter(Mandatory = $true)][string]$ShotsDir,
  [double]$SecondsPerShot = 2.5
)

$ff = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
if (-not $ff) { $ff = Get-ChildItem 'C:\Tools\ffmpeg', 'C:\ffmpeg', "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName }
if (-not $ff) { 'ffmpeg not found'; exit 1 }

$vids = Join-Path $env:USERPROFILE "Videos\$Folder"
$shots = Get-ChildItem $ShotsDir -Include '*.jpg', '*.png' -Recurse | Sort-Object LastWriteTime
$recs = Get-ChildItem "$vids\*.mp4" | Where-Object Name -notlike '*-slideshow.mp4' | Sort-Object Name | ForEach-Object {
  [pscustomobject]@{ File = $_; Start = [datetime]::ParseExact($_.Name.Substring(0, 15), 'yyyyMMdd-HHmmss', $null) }
}
$tmp = Join-Path $env:TEMP 'qa-slides'
for ($i = 0; $i -lt $recs.Count; $i++) {
  $r = $recs[$i]
  if ($r.File.Length -gt 100KB) { continue }
  $end = if ($i + 1 -lt $recs.Count) { $recs[$i + 1].Start } else { Get-Date }
  $mine = @($shots | Where-Object { $_.LastWriteTime -ge $r.Start -and $_.LastWriteTime -lt $end })
  if (-not $mine) { "SKIP (no screenshots): $($r.File.Name)"; continue }
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Force $tmp | Out-Null
  $list = foreach ($s in $mine) { "file '$($s.FullName -replace '\\','/')'"; "duration $SecondsPerShot" }
  $list += "file '$(($mine[-1].FullName) -replace '\\','/')'"
  $listFile = Join-Path $tmp 'list.txt'
  $list | Set-Content -Encoding ascii $listFile
  $out = $r.File.FullName -replace '\.mp4$', '-slideshow.mp4'
  & $ff -hide_banner -loglevel error -y -f concat -safe 0 -i $listFile `
    -vf "scale=800:836:force_original_aspect_ratio=decrease,pad=800:836:(ow-iw)/2:(oh-ih)/2:color=white,format=yuv420p" `
    -r 12 -c:v libx264 -preset veryfast -crf 26 $out
  if (Test-Path $out) {
    Remove-Item $r.File.FullName
    "BUILT $([System.IO.Path]::GetFileName($out)) from $($mine.Count) screenshots"
  } else { "FAILED $($r.File.Name)" }
}
