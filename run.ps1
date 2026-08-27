<#
  run.ps1 - launch bienify on the connected Android phone without the device picker.

  `flutter run` with no -d lists every target (phone, Windows, Chrome, Edge) and
  waits for a keypress. This resolves the phone's serial from adb and passes it
  through, so the app just starts. Any extra arguments are forwarded to
  `flutter run` verbatim, e.g.  .\run.ps1 --release  /  .\run.ps1 --flavor dev
#>

$ErrorActionPreference = 'Stop'

# Prefer the SDK's adb so a stray copy elsewhere on PATH can't cause a
# "adb server version doesn't match this client" handshake failure.
$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { 'C:\Android\Sdk' }
$adb = Join-Path $sdk 'platform-tools\adb.exe'
if (-not (Test-Path $adb)) { $adb = 'adb' }

# Sweep up logcat readers orphaned by a previous run that was killed rather than
# quit; they keep sockets open on the adb server and make the next run flaky.
Get-CimInstance Win32_Process -Filter "Name='adb.exe'" -ErrorAction SilentlyContinue |
  Where-Object { $_.CommandLine -match 'logcat' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

$serials = @(& $adb devices |
  Select-Object -Skip 1 |
  Where-Object { $_ -match '^\S+\s+device$' } |
  ForEach-Object { ($_ -split '\s+')[0] })

if ($serials.Count -eq 0) {
  Write-Host 'No authorised Android device.' -ForegroundColor Red
  & $adb devices -l
  Write-Host 'Check the cable, then confirm the "Allow USB debugging" prompt on the phone.'
  exit 1
}

if ($serials.Count -gt 1) {
  Write-Host 'More than one device attached - pick a serial and pass it yourself:' -ForegroundColor Yellow
  $serials | ForEach-Object { Write-Host "  flutter run -d $_" }
  exit 1
}

Write-Host "Running on $($serials[0])" -ForegroundColor Green
& flutter run -d $serials[0] @args
