<#
.SYNOPSIS
Test accessibility of a remote PC
.NOTES
Author: Dominik Britz
www.dominikbritz.com
#>

$Computername =

If (-not (Test-Connection -ComputerName $Computername -Count 1 -quiet))
{
   Write-Host "$Computername cannot be pinged" -foregroundcolor red         
}
elseif (-not (Test-Path "\\$Computername\admin$")) 
{
      Write-Host "$Computername 's admin share is unavailable" -foregroundcolor red         
}
