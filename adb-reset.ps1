<#
  adb-reset.ps1 - recover from adb daemon errors.

  Use when adb reports "device offline", "daemon not running", an unresponsive
  server, or when the phone stops showing up in `flutter devices`. Tears the adb
  server down completely, including any stray client processes holding sockets
  open, then brings it back up and reports what it sees.
#>

$ErrorActionPreference = 'Continue'

$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { 'C:\Android\Sdk' }
$adb = Join-Path $sdk 'platform-tools\adb.exe'

Write-Host 'Stopping adb server...' -ForegroundColor Cyan
& $adb kill-server | Out-Null

# kill-server only asks the server to exit; clients such as logcat readers can
# survive it and immediately respawn a server of their own.
Get-Process adb -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Host 'Starting adb server...' -ForegroundColor Cyan
& $adb start-server | Out-Null
Start-Sleep -Seconds 1

& $adb devices -l
Write-Host ''
Write-Host 'If the phone shows "unauthorized", accept the USB debugging prompt on it.' -ForegroundColor Yellow
Write-Host 'If it is missing entirely, unplug and replug the cable, then rerun this.' -ForegroundColor Yellow
