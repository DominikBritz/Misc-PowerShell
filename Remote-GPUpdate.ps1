<#
.SYNOPSIS
This is a simple PowerShell script to execute gpuptade /target:computer on another computer

.PARAMETER ComputerName
Computer on which the command should run

.EXAMPLE
.\Remote-GPUpdate.ps1 -ComputerName Computer01

.EXAMPLE
"Computer01","Computer02" | .\Remote-GPUpdate.ps1

.EXAMPLE
Computerlist.txt | .\Remote-GPUpdate.ps1

.INPUTS
This script accepts pipeline input

.OUTPUTS
This script does not generate output

.NOTES
https://github.com/DominikBritz
#>
[CmdletBinding()]
PARAM
(
    [Parameter(ValueFromPipeline=$True)]
    [ValidateNotNullOrEmpty()]
    [string]$ComputerName = $env:COMPUTERNAME
)

If (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)
{
    Write-Output "Processing $ComputerName"
    Invoke-WmiMethod -class Win32_process -name Create -ArgumentList "cmd.exe /c gpupdate /target:computer" -ComputerName $ComputerName | out-null
}