#Requires -Version 3
#Requires -RunAsAdministrator
<#
    .SYNOPSIS
    This script automates the creation of the necessary keyword prefer and a shortcut for Citrix Receiver to not open another session
    but instead execute the local installed application
    
    .DESCRIPTION
    In the good old times we had pnagent and with it a dead simple way to customize the start menu of our users with the apps they have access to.
    Things are changing with storefront. Receiver still pushes icons of the users apps into the start menu. But as apps and desktops 
    can't share a single session, when they click on an icon pushed by Receiver, a second session is started. Gladly there is a way to tell Receiver
    if he is able to find a local application then start this instead of a new Citrix session. For that you have to edit the describtion of a 
    published app and the string KEYWORDS:prefer=Shortcutname and create a corresponding shortcut with the name "Shortcutname" so that Receiver is able
    to match the published app with the local shortcut. For details have a look here: http://blogs.citrix.com/2015/01/06/shortcut-creation-for-locally-installed-apps-via-citrix-receiver/
    Have fun editing all your hundreds or thousands of apps...
    
    This script creates the app description and the shortcut for all apps in your site (You can limit it to specific apps or folders - see the parameters). 
    It does that by enumerating all your apps. Then it sets the application name as prefer keyword and the name of the shortcut.
    
    The script has to be executed on a Citrix Controller with elevated rights.

    .PARAMETER Application
    By default the script will process all applications in the site. However, you can limit the processing by adding the parameter application
    and specifying the name of an application to process. Wildcards are allowed.
    
    .PARAMETER StudioFolder
    By default the script will process all applications in the site. However, you can limit the processing by adding the parameter StudioFolder
    and specifying the name of an application folder to process. All applications in the specified folder will be processed. Wildcards are allowed.
    
    .PARAMETER ExportPath
    The path where the shortcuts will be saved. If the path does not exist, the script will create it for you.
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
Try
{
    $DestinationPath = $(Join-Path $DestinationPath $AppName)
    If (Test-Path $DestinationPath)
    {
        Write-Error "The shortcut $DestinationPath does already exist. Your application names have to be unique as Citrix Receiver supports only one folder for the shortcuts."
    }
    Else
    {
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($DestinationPath)
        $Shortcut.TargetPath = $AppCMD
        $Shortcut.Arguments = $AppArguments
        $Shortcut.Save()
    }
}
Catch
{
    Throw $_
}
}

Try
{
    Write-Output 'Loading Citrix PowerShell Cmdlets'
    Add-PSSnapin Citrix*
}
Catch
{
    Write-Error 'Could not load the needed Citrix Snapins.'
    Write-Error 'You have to run this script on a Citrix Controller.'
}

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
