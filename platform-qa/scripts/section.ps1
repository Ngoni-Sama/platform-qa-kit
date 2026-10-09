# Mark the start of a test section, so make-videos.ps1 can group the browser
# screenshots taken during it into one video.
#   section.ps1 <section-name> [-Folder <Videos subfolder>]
# Appends "<ISO time>,<name>" to %USERPROFILE%\Videos\<Folder>\sections.csv
param(
  [Parameter(Mandatory = $true, Position = 0)][string]$Name,
  [string]$Folder = 'qa-tests'
)
$outDir = Join-Path $env:USERPROFILE "Videos\$Folder"
New-Item -ItemType Directory -Force $outDir | Out-Null
$safe = ($Name -replace '[^\w\-]+', '-').Trim('-')
$line = '{0},{1}' -f (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'), $safe
Add-Content -Path (Join-Path $outDir 'sections.csv') -Value $line -Encoding ascii
Write-Output "SECTION -> $safe"
