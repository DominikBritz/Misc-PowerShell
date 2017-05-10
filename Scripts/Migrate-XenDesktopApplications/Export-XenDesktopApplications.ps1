<#
.SYNOPSIS
Exports applications from a Citrix XenDesktop or XenApp 7.8 desktop group

.PARAMETER ExportFolder
Folder where to save the exported files. In this folder the script creates a folder for each DesktopGroup.

.PARAMETER DesktopGroup
The Citrix Studio Desktop Delivery Group which will be the source for the export

.EXAMPLE .\Export-XenDesktopApplications.ps1 -ExportFolder C:\Export -DesktopGroup ProductionDesktop
Exports all published apps which are published to the desktop delivery group "ProductionDesktop" to the folder "C:\Export" 
#>

Param(
    [Parameter(Position=0,
    Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
	[String]$ExportFolder,

    [Parameter(Position=1,
    Mandatory=$True)]
    [ValidateNotNullOrEmpty()] 
    [String]$DesktopGroup
)

$scriptDirectory = Split-Path $myInvocation.MyCommand.Path
function Test-IsAdmin {

([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')

}

#region Script
if (!(Test-IsAdmin)){
    throw 'Please run this script with admin priviliges'
}

Add-PSSnapin citrix* -Verbose

if (!(Test-Path -Path $ExportFolder\$DesktopGroup))
{
    Write-Verbose "Exportfolder $ExportFolder does not exist. Create it."
    New-Item -ItemType directory -Path $ExportFolder\$DesktopGroup|out-null
}

$DesktopGroupUid = (Get-BrokerDesktopGroup -Name $DesktopGroup).Uid
Get-BrokerApplication -DesktopGroupUid $DesktopGroupUid | ForEach-Object{
    $CurrentAppHashTable = @{}
    $CurrentApp = $_
    $CurrentApp|Get-Member -MemberType Property|foreach-object{
    $_.name
    }|foreach-object{
        $CurrentAppHashTable.Add($_, $(($CurrentApp).$($_)))
    }
    $BrokerIconUid = ($CurrentApp).IconUid
    $BrokerEnCodedIconData = (Get-BrokerIcon -Uid $BrokerIconUid).EncodedIconData
    $CurrentAppHashTable.Add('EncodedIconData', $BrokerEnCodedIconData)
    
    Get-BrokerConfiguredFTA | Where-Object {$_.ApplicationUid -eq $CurrentApp.Uid} | ForEach-Object -Process {
        $FTAUid = "FTA-" + "$($_.Uid)"
        $FTA = @{}
        $FTA.Add('ContentType',$_.ContentType)
        $FTA.Add('ExtensionName',$_.ExtensionName)
        $FTA.Add('HandlerDescription',$_.HandlerDescription)
        $FTA.Add('HandlerName',$_.HandlerName)
        $FTA.Add('HandlerOpenArguments',$_.HandlerOpenArguments)
        $CurrentAppHashTable.Add("$FTAUid", $FTA)
    }

    $AppName = $_.ApplicationName -replace ' ','_'
    $Extension = 'json'
    $Filename = $Appname + '.' + $Extension
    $Content = $CurrentAppHashTable|ConvertTo-Json -Compress #-Compress is needed because of a bug in PowerShell -> http://stackoverflow.com/questions/23552000/convertto-json-throws-error-when-using-a-string-terminating-in-backslash
    $Content|Set-Content -Path $(join-path $ExportFolder\$DesktopGroup $Filename) -Force
}

Write-Verbose 'Finished'

#endregion