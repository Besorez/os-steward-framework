<#
.SYNOPSIS
    Open the Mac screen in a browser app window, scaled to the window (noVNC behind a local websockify).
.DESCRIPTION
    If nothing listens on 127.0.0.1:<Port>, starts "pyw -m websockify --web <noVNC dir> 127.0.0.1:<Port>
    <mac>:5900" hidden (Python + "pip install websockify" required). Then opens Chrome as an --app
    window with its OWN --user-data-dir (a normal profile keeps serving a cached, unpatched rfb.js),
    Translate disabled, and noVNC's vnc.html with autoconnect, resize=scale and reconnect. noVNC must
    carry the local patch that prefers security type 2 (VncAuth) when offered; the script warns if
    core/rfb.js does not look patched (see the playbook, section 3).
.PARAMETER MacHost
    Mac address, e.g. 192.0.2.40.
.PARAMETER NoVncPath
    Folder of an unpacked noVNC release (contains vnc.html and core\rfb.js). Not part of this repository.
.PARAMETER PasswordFile
    Optional plain-text VNC password file. When given, the password goes into the URL (localhost only,
    kept in the dedicated profile's history); when omitted, noVNC asks for it.
.PARAMETER ProfileDir
    Chrome user-data-dir. Default: %LOCALAPPDATA%\OSSteward-playbooks\mac-access\chrome-profile.
.EXAMPLE
    .\Start-MacScreen.ps1 -MacHost 192.0.2.40 -NoVncPath C:\Tools\noVNC -PasswordFile $env:LOCALAPPDATA\OSSteward-playbooks\mac-access\vnc-password.txt
.NOTES
    Starts processes only. Rollback: close the window; stop the pyw.exe websockify process.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$MacHost,
    [Parameter(Mandatory)][string]$NoVncPath,
    [string]$PasswordFile = '',
    [int]$Port = 6080,
    [int]$VncPort = 5900,
    [string]$ProfileDir = "$env:LOCALAPPDATA\OSSteward-playbooks\mac-access\chrome-profile"
)
$ErrorActionPreference = 'Stop'
$rfb = Join-Path $NoVncPath 'core\rfb.js'
if (-not (Test-Path (Join-Path $NoVncPath 'vnc.html'))) { throw "no vnc.html in $NoVncPath" }
if (-not (Select-String -Path $rfb -SimpleMatch 'types.includes(securityTypeVNCAuth)' -Quiet)) {
    Write-Warning 'core\rfb.js is not patched to prefer VncAuth: noVNC will ask for a Mac user name + password (ARD, type 30)'
}

function Test-Listening { [bool](Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) }
if (-not (Test-Listening)) {
    if (-not (Get-Command pyw -ErrorAction SilentlyContinue)) { throw 'pyw (Python launcher) not found; install Python, then: py -m pip install websockify' }
    Start-Process pyw -ArgumentList '-m', 'websockify', '--web', "`"$NoVncPath`"", "127.0.0.1:$Port", "${MacHost}:$VncPort" -WindowStyle Hidden
    for ($i = 0; $i -lt 40 -and -not (Test-Listening); $i++) { Start-Sleep -Milliseconds 250 }
    if (-not (Test-Listening)) { throw "websockify did not start on 127.0.0.1:$Port (py -m pip install websockify?)" }
}

$url = "http://127.0.0.1:$Port/vnc.html?autoconnect=1&resize=scale&reconnect=1&path=websockify"
if ($PasswordFile) { $url += '&password=' + [uri]::EscapeDataString((Get-Content $PasswordFile -TotalCount 1).Trim()) }
$chrome = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
            "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $chrome) { throw 'Chrome not found; open the noVNC URL in any browser with a fresh profile instead' }
Start-Process $chrome "--app=$url", "--user-data-dir=`"$ProfileDir`"", '--disable-features=Translate', '--no-first-run'
Write-Output "screen window opened via 127.0.0.1:$Port -> ${MacHost}:$VncPort"
