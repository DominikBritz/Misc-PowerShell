<# 
     .SYNOPSIS 
     This script will remove all IP information from the system
#>

#Requires -Version 3
#Requires -RunAsAdministrator

$Items = @('DhcpDefaultGateway','DhcpDomain','DhcpIPAddress','DhcpNameServer','DhcpServer','DhcpSubnetMask','DhcpSubnetMaskOpt')

Foreach ($Item in $Items){
    Get-ChildItem -Path HKLM:\SYSTEM -Recurse -ErrorAction SilentlyContinue | Where-Object {$_.Property -eq $Item } | Get-ItemProperty -Name $Item | Set-ItemProperty -Name $Item -Value $null
}
