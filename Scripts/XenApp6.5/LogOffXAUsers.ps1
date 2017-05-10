<#
	.SYNOPSIS
	Get all XenApp 6.5 sessions (except ICA and RDP listener) and force log off
#>
Try
{
	Write-Output 'Start'	
	Add-PSSnapin citrix*
	Write-Output 'Get all sessions (except ICA and RDP listener) and force log off'	
	Get-XASession -ServerName $env:computername | foreach-object -process {if (($_.SessionID -notmatch "65536") -and ($_.SessionID -notmatch "65537")) {$_.SessionID}} | Stop-XASession
	Write-Output 'Finished'
}
Catch
{
	Throw $_
}