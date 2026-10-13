# JARVIS - background launcher: starts the server hidden and opens the app window.
$ErrorActionPreference = "Continue"
$data = Join-Path $HOME "lab\jarvis-data"
New-Item -ItemType Directory -Force $data | Out-Null
Start-Transcript -Path (Join-Path $data "launcher.log") -Force | Out-Null
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User") + ";" + (Join-Path $env:APPDATA "npm")
$dir = Join-Path $HOME "lab\jarvis"
$url = "http://localhost:5173"

function Test-Url($u) { try { (Invoke-WebRequest $u -UseBasicParsing -TimeoutSec 2).StatusCode -eq 200 } catch { $false } }

# One-time: proper shortcuts with the JARVIS icon (desktop + autostart).
$vbs = Join-Path $HOME "lab\JARVIS.vbs"
$ico = Join-Path $data "jarvis.ico"
$ws = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath("Desktop")
$startup = [Environment]::GetFolderPath("Startup")
foreach ($target in @((Join-Path $desktop "JARVIS.lnk"), (Join-Path $startup "JARVIS.lnk"))) {
  if (-not (Test-Path $target)) {
    $s = $ws.CreateShortcut($target)
    $s.TargetPath = "$env:WINDIR\System32\wscript.exe"
    $s.Arguments = '"' + $vbs + '"'
    $s.WorkingDirectory = Join-Path $HOME "lab"
    if (Test-Path $ico) { $s.IconLocation = $ico }
    $s.Description = "J.A.R.V.I.S."
    $s.Save()
  }
}
# The startup .vbs copy is replaced by the shortcut above; the old .cmd launcher too.
Remove-Item (Join-Path $startup "JARVIS.vbs") -ErrorAction SilentlyContinue
Remove-Item (Join-Path $desktop "JARVIS.cmd") -ErrorAction SilentlyContinue

if (-not (Test-Url "http://localhost:8787/health")) {
  if (Get-Command git -ErrorAction SilentlyContinue) {
    git -C $dir fetch origin 2>&1 | Out-Host
    if ($LASTEXITCODE -eq 0) { git -C $dir reset --hard origin/main 2>&1 | Out-Host }
  }
  $stamp = Join-Path $dir "node_modules\.package-lock.json"
  if (-not (Test-Path $stamp) -or ((Get-Item (Join-Path $dir "package.json")).LastWriteTime -gt (Get-Item $stamp).LastWriteTime)) {
    Push-Location $dir; npm.cmd install --no-audit --no-fund 2>&1 | Out-Host; Pop-Location
  }
  $serverLog = Join-Path $data "server.log"
  Start-Process -WindowStyle Hidden -FilePath "cmd.exe" -WorkingDirectory $dir -ArgumentList "/c npm.cmd start > `"$serverLog`" 2>&1"
  for ($i = 0; $i -lt 90; $i++) {
    if ((Test-Url "http://localhost:8787/health") -and (Test-Url $url)) { break }
    Start-Sleep 1
  }
}

$edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($edge) { Start-Process $edge "--app=$url --window-size=1280,820" }
else { Start-Process $url }
Stop-Transcript | Out-Null
