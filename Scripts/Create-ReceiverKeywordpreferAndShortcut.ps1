<#
    .SYNOPSIS
    This script automates the creation of the necessary keyword prefer and a shortcut for Citrix Receiver to not open another session
    but instead execute the local installed application

    .PARAMETER Application

    .PARAMETER StudioFolder

    .PARAMETER ExportPath
#>
[Cmdletbinding()]
PARAM
(
    [ValidateNotNullOrEmpty()]
    $Application,

    [ValidateNotNullOrEmpty()]
    $StudioFolder,

    [ValidateNotNullOrEmpty()]
    [ValidateScript({Try
                    {If (-not(Test-Path $_)) {New-Item $ExportPath -ItemType Directory}}
                    Catch{$_.Exception.Message}        
                    })]
    $ExportPath
)

Function Create-KeywordPrefer{
PARAM
(
    $AppObject,
    $AppName,
    $AppCMD,
    $AppArguments,
    $DestinationPath
)

Set-BrokerApplication -InputObject $_ -Description "KEYWORDS:prefer=$AppName"

}

Function Create-Shortcut{
PARAM
(
    $AppName,
    $AppCMD,
    $AppArguments,
    $DestinationPath
)

$DestinationPath = $(Join-Path $DestinationPath $AppName)

$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($DestinationPath)
$Shortcut.TargetPath = $AppCMD
$Shortcut.Arguments = $AppArguments
$Shortcut.Save()
}

Write-Output 'Loading Citrix PowerShell Cmdlets'
Add-PSSnapin Citrix*

If ($Application)
{
    Write-Output "Starting in application mode"
    Get-BrokerApplication | Where-Object {$_.Name -match $Application} | ForEach-Object {
        Write-Output "Processing application $Application"  
        $AppName = $AppName.replace(' ','')
        Create-KeywordPrefer -AppObject $_ -AppName $_.ApplicationName -AppCMD $_.CommandLineExecutable -AppArguments $_.CommandLineArguments -DestinationPath $ExportPath
        Create-Shortcut -AppName $AppName -AppCMD $_.CommandLineExecutable -AppArguments $_.CommandLineArguments -DestinationPath $ExportPath
    }
}

If ($StudioFolder)
{
    Write-Output 'Starting in folder mode'
    Get-BrokerApplication | Where-Object {$_.AdminFolderName -match $StudioFolder} | ForEach-Object {
        Write-Output "Processing application $Application"  
        $AppName = $AppName.replace(' ','')
        Create-KeywordPrefer -AppObject $_ -AppName $_.ApplicationName -AppCMD $_.CommandLineExecutable -AppArguments $_.CommandLineArguments -DestinationPath $ExportPath
        Create-Shortcut -AppName $AppName -AppCMD $_.CommandLineExecutable -AppArguments $_.CommandLineArguments -DestinationPath $ExportPath
    }
}

If ($Application -and $StudioFolder)
{
    Write-Output 'Starting in application/folder mode'
    Get-BrokerApplication | Where-Object {($_.Name -match $Application) -and ($_.AdminFolderName -match $StudioFolder)} | ForEach-Object {    
        Write-Output "Processing application $Application"
        $AppName = $AppName.replace(' ','')
        Create-KeywordPrefer -AppObject $_ -AppName $_.ApplicationName -AppCMD $_.CommandLineExecutable -AppArguments $_.CommandLineArguments -DestinationPath $ExportPath
        Create-Shortcut -AppName $AppName -AppCMD $_.CommandLineExecutable -AppArguments $_.CommandLineArguments -DestinationPath $ExportPath
    }
}

If (-not($Application -and $StudioFolder))
{
    Write-Output 'Starting in all applications mode'
    Get-BrokerApplication | ForEach-Object {    
        Write-Output "Processing application $Application"
        $AppName = $AppName.replace(' ','')
        Create-KeywordPrefer -AppObject $_ -AppName $_.ApplicationName -AppCMD $_.CommandLineExecutable -AppArguments $_.CommandLineArguments -DestinationPath $ExportPath
        Create-Shortcut -AppName $AppName -AppCMD $_.CommandLineExecutable -AppArguments $_.CommandLineArguments -DestinationPath $ExportPath
    }
}
