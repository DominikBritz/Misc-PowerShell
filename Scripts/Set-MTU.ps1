$Ethernet = 'Ethernet'
$LogPath = "$env:windir\Temp\Set-MTU.log"

Start-Transcript -Path $LogPath -Force | out-null

$ModuleName = "SBeMail"

$Destination = "$env:ProgramFiles\WindowsPowerShell\Modules\$ModuleName"
If ( -not (Test-Path -Path $Destination)) {
    New-Item -Path $Destination -ItemType directory -force -Confirm:$false
}
$Path = Split-Path $script:MyInvocation.MyCommand.Path
$Path = "$Path\SBeMail"
Copy-Item -Path "$Path\$ModuleName.psm1","$Path\$ModuleName.psd1" -Destination $Destination -Force -Confirm:$false
Unblock-File "$Destination\$ModuleName.psm1","$Destination\$ModuleName.psd1" -Confirm:$false 
Remove-Module $ModuleName -ErrorAction SilentlyContinue
Import-Module $ModuleName -DisableNameChecking

$AdapterName = ''
$AdapterName = $(Get-NetAdapter | Where { $_.Name -eq $Ethernet}).Name

Write-Verbose "Adapter name we look for: $Ethernet" -Verbose

If ($AdapterName -eq $Ethernet)
{
    Write-Verbose "Adapter $Ethernet found" -Verbose
    $AdapterIndex = $(Get-NetAdapter | Where { $_.Name -eq $Ethernet}).InterfaceIndex
    Write-Verbose "Adapter interface index: $AdapterIndex" -Verbose
    Write-Verbose "Running: netsh interface ipv4 set subinterface $AdapterIndex mtu=1400 store=persistent" -Verbose
    Write-Verbose "Exit code below" -Verbose
    (Start-Process -FilePath netsh -ArgumentList "interface ipv4 set subinterface $AdapterIndex mtu=1400 store=persistent" -NoNewWindow -PassThru -Wait).ExitCode
    
    Write-Verbose "Running: netsh interface ipv6 set subinterface $AdapterIndex mtu=1400 store=persistent" -Verbose
    Write-Verbose "Exit code below" -Verbose
    (Start-Process -FilePath netsh -ArgumentList "interface ipv6 set subinterface $AdapterIndex mtu=1400 store=persistent" -NoNewWindow -PassThru -Wait).ExitCode
}

Else
{
    Write-Verbose "No adapter named $Ethernet found. Please set MTU manually." -Verbose
    Stop-Transcript
    #Send-MailMessage -From "$env:COMPUTERNAME@vastlimits.com" -To "dominik@vastlimits.com" -Attachments $LogPath -Subject "Failed to set MTU for $env:COMPUTERNAME" -Body "No adapter named $Ethernet found. Please set MTU manually."
    
    $Body = Get-Content $LogPath -Raw

    Send-Email -From "MDT1@vastlimits.com" -To "info@uberagent.com" -Subject "Failed to set MTU for $env:COMPUTERNAME" -Body $Body -MyFQDN 'ad.int.vastlimits.com' -Verbose
    
    exit
}

Stop-Transcript | out-null
