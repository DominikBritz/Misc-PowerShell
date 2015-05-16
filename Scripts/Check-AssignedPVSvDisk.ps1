<#
.SYNOPSIS
This is a simple PowerShell script to check the assigned Citrix Provisioning vDisk of a remote computer

.PARAMETER ComputerName
Computer on which the command should run

.EXAMPLE
.\Check-AssignedPVSvDisk.ps1 -ComputerName Computer01

.EXAMPLE
"Computer01","Computer02" | .\Check-AssignedPVSvDisk.ps1

.EXAMPLE
Computerlist.txt | .\Check-AssignedPVSvDisk.ps1

.INPUTS
This script accepts pipeline input

.OUTPUTS
This script gives you a hash with computernames and assigned vdisks

.NOTES
Author: Dominik Britz
Source: https://github.com/DominikBritz
#>

[CmdletBinding()]
PARAM
(
    [Parameter(ValueFromPipeline=$True)]
    [ValidateNotNullOrEmpty()]
    [string]$ComputerName = $env:COMPUTERNAME
)

Begin
{
    $Hash = @{}
}

Process
{
    If (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)
    {
        Write-Output "Processing $ComputerName"
        $vDisk = Get-Content "\\$ComputerName\C$\Personality.ini" | % {If ($_ -match "DiskName") {(($_).split("="))[1]}}
        $Hash.Add($ComputerName,$vDisk)
    }
    Else
    {
        Write-Error "Could not reach $ComputerName"
    }
}

End
{
    Write-Output $Hash
}
