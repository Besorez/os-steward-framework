<#
.SYNOPSIS
    Read-only report of everything an operator needs after enabling remote access: edition, addresses,
    adapters, shares, sshd/RDP state, volumes, physical disk health.
#>
[CmdletBinding()]
param()
$ErrorActionPreference = 'SilentlyContinue'
$os = Get-CimInstance Win32_OperatingSystem
'Computer : {0}  ({1}, build {2})' -f $env:COMPUTERNAME, $os.Caption, $os.Version
'User     : {0}' -f $env:USERNAME
'Adapters :'
Get-NetAdapter -Physical | Select-Object Name, Status, LinkSpeed, MacAddress | Format-Table -AutoSize | Out-String
'IPv4     : {0}' -f ((Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } | ForEach-Object { "$($_.InterfaceAlias)=$($_.IPAddress)" }) -join ', ')
'Profiles : {0}' -f ((Get-NetConnectionProfile | ForEach-Object { "$($_.InterfaceAlias)=$($_.NetworkCategory)" }) -join ', ')
'Shares   : {0}' -f ((Get-SmbShare | Where-Object Path -match '^[A-Z]:\\$' | ForEach-Object { $_.Name }) -join ', ')
'sshd     : {0}' -f ((Get-Service sshd).Status)
'RDP      : {0}' -f $(if ((Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server').fDenyTSConnections -eq 0) { 'enabled' } else { 'disabled' })
'Hello-only sign-in for MS accounts (blocks RDP passwords when 2): {0}' -f (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device').DevicePasswordLessBuildVersion
''
'Volumes:'
Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' } |
    Select-Object DriveLetter, FileSystemLabel, @{n='SizeGB';e={[math]::Round($_.Size/1GB)}}, @{n='FreeGB';e={[math]::Round($_.SizeRemaining/1GB)}} | Format-Table -AutoSize
'Physical disks:'
Get-PhysicalDisk | Select-Object FriendlyName, MediaType, HealthStatus, @{n='SizeGB';e={[math]::Round($_.Size/1GB)}} | Format-Table -AutoSize
