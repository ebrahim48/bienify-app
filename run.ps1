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

$serial = $serials[0]

# The phone's own localhost is tunnelled back to this machine by the
# `openBienifyApiTunnel` Gradle task in android/app/build.gradle.kts. That task
# runs on a *build*, and the tunnel does not survive a USB replug, an adb server
# restart, or `adb kill-server` — so an app already installed on the phone can be
# opened with no tunnel at all. Every request then fails at the TCP layer and the
# app says "Cannot reach the server. Check your connection.", which is true and
# tells you nothing about why. Opening it here too is idempotent and costs a few
# milliseconds; the alternative is that failure with no explanation.
$port = if ($env:BIENIFY_API_PORT) { $env:BIENIFY_API_PORT } else { 3500 }

# A tunnel to a port nothing serves is the same failure one step later, so say
# so now rather than letting the phone report it as a network fault.
if (-not (Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)) {
  Write-Host "Nothing is listening on port $port - start the backend first:" -ForegroundColor Yellow
  Write-Host '  cd ..\Backend-Beinify; npm run dev'
}

& $adb -s $serial reverse "tcp:$port" "tcp:$port" | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host "adb reverse failed - the phone will not reach the backend." -ForegroundColor Red
} else {
  # Confirmed rather than assumed: `adb reverse` exits 0 for a tunnel that a
  # later replug has already silently dropped.
  $reachable = & $adb -s $serial shell "echo | toybox nc -w 3 127.0.0.1 $port >/dev/null 2>&1 && echo up || echo down"
  if ($reachable -notmatch 'up') {
    Write-Host "Tunnel opened but port $port is still not reachable from the phone." -ForegroundColor Yellow
  }
}

# The base URL the app is built with, stated rather than inherited.
#
# `ApiConstants.baseUrl` defaults to http://localhost:3500, which on a phone
# means the phone itself and only reaches this machine through the tunnel
# opened above. That default is invisible from here: nothing in this script
# said which host the app would end up calling, so a run against a backend on
# another port or another machine needed the dart-define typed out by hand and
# was usually forgotten. Passing it explicitly makes the choice readable in the
# line this script prints, and $env:BIENIFY_API_BASE_URL overrides it — set it
# to http://<this-machine's-LAN-IP>:$port to work without a USB tunnel.
$baseUrl = if ($env:BIENIFY_API_BASE_URL) { $env:BIENIFY_API_BASE_URL } else { "http://localhost:$port" }

Write-Host "Running on $serial (API $baseUrl, localhost:$port tunnelled)" -ForegroundColor Green
& flutter run -d $serial "--dart-define=BIENIFY_API_BASE_URL=$baseUrl" @args
