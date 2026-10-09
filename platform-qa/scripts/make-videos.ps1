# Build one browser-only video per test section from the screenshots Claude took
# of the browser tab. Because the frames come from the browser tab itself, nothing
# else on the tester's screen (other apps, other Claude sessions, the chat) can appear.
#   make-videos.ps1 -ShotsDir <folder with the screenshot files> [-Folder <Videos subfolder>]
# ShotsDir is the folder in each screenshot result's "source:" path
# (...\.claude\projects\<project>\<session>\tool-results). Sections come from
# sections.csv written by section.ps1. Output: <Videos\Folder>\videos\NN-<section>.mp4
# plus videos\posters\NN-<section>.jpg; put report.html in <Videos\Folder>.
param(
  [Parameter(Mandatory = $true)][string]$ShotsDir,
  [string]$Folder = 'qa-tests',
  [double]$SecondsPerShot = 3
)

$ff = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
if (-not $ff) { $ff = Get-ChildItem 'C:\Tools\ffmpeg', 'C:\ffmpeg', "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName }
if (-not $ff) { 'ffmpeg not found - see README'; exit 1 }

$outDir = Join-Path $env:USERPROFILE "Videos\$Folder"
$csv = Join-Path $outDir 'sections.csv'
if (-not (Test-Path $csv)) { "No sections.csv in $outDir - run section.ps1 at the start of each section"; exit 1 }
$sections = Get-Content $csv | Where-Object { $_ } | ForEach-Object {
  $t, $n = $_ -split ',', 2
  [pscustomobject]@{ Start = [datetime]::Parse($t); Name = $n }
} | Sort-Object Start

# Browser screenshots only: the built-in browser saves them as ...Browser-blob-*.jpg/.png
$shots = Get-ChildItem $ShotsDir -File | Where-Object { $_.Name -like '*Browser-blob-*' -and $_.Extension -in '.jpg', '.jpeg', '.png' } | Sort-Object LastWriteTime
$tmp = Join-Path $env:TEMP 'qa-make-videos'
for ($i = 0; $i -lt $sections.Count; $i++) {
  $s = $sections[$i]
  $end = if ($i + 1 -lt $sections.Count) { $sections[$i + 1].Start } else { Get-Date }
  # one image format per video: the concat demuxer can't mix jpg and png
  $mine = @($shots | Where-Object { $_.LastWriteTime -ge $s.Start -and $_.LastWriteTime -lt $end -and $_.Extension -ne '.png' })
  $vidDir = Join-Path $outDir 'videos'   # report.html sits in $outDir and links videos/...
  New-Item -ItemType Directory -Force $vidDir | Out-Null
  $out = Join-Path $vidDir ('{0:D2}-{1}.mp4' -f ($i + 1), $s.Name)
  if (-not $mine) { "SKIP (no screenshots): $($s.Name)"; continue }
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Force $tmp | Out-Null
  $list = foreach ($f in $mine) { "file '$($f.FullName -replace '\\','/')'"; "duration $SecondsPerShot" }
  $list += "file '$(($mine[-1].FullName) -replace '\\','/')'"
  $listFile = Join-Path $tmp 'list.txt'
  $list | Set-Content -Encoding ascii $listFile
  # Web playback: faststart (plays before fully downloaded), a keyframe every second
  # (smooth seeking), still-image tuning. Every frame is 800x836 to match the report's
  # aspect-ratio box.
  & $ff -hide_banner -loglevel error -y -f concat -safe 0 -i $listFile `
    -vf "scale=800:836:force_original_aspect_ratio=decrease,pad=800:836:(ow-iw)/2:(oh-ih)/2:color=white,format=yuv420p" `
    -r 12 -c:v libx264 -preset medium -tune stillimage -crf 23 -g 12 -keyint_min 12 -movflags +faststart -an $out
  if (Test-Path $out) {
    # Poster frame for click-to-play (<video preload="none" poster=...>)
    $posterDir = Join-Path $vidDir 'posters'
    New-Item -ItemType Directory -Force $posterDir | Out-Null
    & $ff -hide_banner -loglevel error -y -ss 1 -i $out -frames:v 1 -q:v 4 (Join-Path $posterDir ([IO.Path]::GetFileNameWithoutExtension($out) + '.jpg'))
    "BUILT $([IO.Path]::GetFileName($out)) from $($mine.Count) screenshots"
  } else { "FAILED $($s.Name)" }
}
