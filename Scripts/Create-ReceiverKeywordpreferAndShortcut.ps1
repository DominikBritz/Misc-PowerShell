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
    and specifying the name of an application to process. Wildcards are allowed. The parameter can be combined with the parameter 'StudioFolder'.
    
    .PARAMETER StudioFolder
    By default the script will process all applications in the site. However, you can limit the processing by adding the parameter StudioFolder
    and specifying the name of an application folder to process. All applications in the specified folder will be processed. Wildcards are allowed. 
    The parameter can be combined with the parameter 'Application'.
    
    .PARAMETER ExportPath
    The path where the shortcuts will be saved. If the path does not exist, the script will create it for you. Parameter is mandatory.

    .EXAMPLE
    .\Create-ReceiverKeywordpreferAndShortcut.ps1 -ExportPath C:\shortcuts
    All applications in the site will be processed. Shortcuts will be saved to C:\shortcuts.

    .EXAMPLE
    .\Create-ReceiverKeywordpreferAndShortcut.ps1 -ExportPath C:\shortcuts -Application Chrome
    All applications which match the string 'Chrome' will be processed, e.g. 'Google Chrome'. Shortcuts will be saved to C:\shortcuts.

    .EXAMPLE
    .\Create-ReceiverKeywordpreferAndShortcut.ps1 -ExportPath C:\shortcuts -StudioFolder Sales
    All applications in the folder 'Sales' will be processed. Shortcuts will be saved to C:\shortcuts.

    .EXAMPLE
    .\Create-ReceiverKeywordpreferAndShortcut.ps1 -ExportPath C:\shortcuts -Application Chrome -StudioFolder Sales
    All applications in the folder 'Sales' which match the string 'Chrome' will be processed. Shortcuts will be saved to C:\shortcuts.
    
    .INPUTS
    This script does not accept input
    
    .OUTPUTS
    This script does not provide output
    
    .NOTES
    Author: Dominik Britz
    Source: https://github.com/DominikBritz
#>

#Requires -Version 3
#Requires -RunAsAdministrator

[Cmdletbinding()]
PARAM
(
    [ValidateNotNullOrEmpty()]
    $Application,

    [ValidateNotNullOrEmpty()]
    $StudioFolder,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({
                        Try
                        {
                           If (-not(Test-Path $_)) {New-Item $_ -ItemType Directory}
                           Else {$True}
                        }
                        Catch
                        {
                           $_.Exception.Message
                        }
                    })]
    $ExportPath
)

#region Functions
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

} #end function

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
    $DestinationPath = $(Join-Path $DestinationPath "$AppName.lnk")
    If (Test-Path $DestinationPath)
    {
        Write-Error "The shortcut $DestinationPath does already exist. Skipping..."
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
} #end function
#endregion

#region Script
Try
{
    Write-Output 'Loading Citrix PowerShell Cmdlets'
    Add-PSSnapin Citrix* -ErrorAction Stop
}
Catch
{
    Write-Error 'Could not load the needed Citrix Snapins.'
    Write-Error 'You have to run this script on a Citrix Controller.'
    Exit
}

If ((-not($Application)) -and (-not($StudioFolder)))
{
    Write-Output 'Starting in all applications mode'
    Get-BrokerApplication | ForEach-Object {    
        Write-Output "Processing application $($_.ApplicationName)"
        $AppName = $_.Name -replace ' ','' -replace "\\","-"
        Create-KeywordPrefer -AppObject $_ -AppName $AppName -AppCMD $_.CommandLineExecutable -AppArguments $_.CommandLineArguments -DestinationPath $ExportPath
        Create-Shortcut -AppName $AppName -AppCMD $_.CommandLineExecutable -AppArguments $_.CommandLineArguments -DestinationPath $ExportPath
    }
}

If ($Application -and $StudioFolder)
{
    Write-Output 'Starting in application/folder mode'
    Get-BrokerApplication | Where-Object {($_.Name -match $Application) -and ($_.AdminFolderName -match $StudioFolder)} | ForEach-Object {    
        Write-Output "Processing application $($_.ApplicationName)"
        $AppName = $_.ApplicationName -replace ' ','' -replace "\\","-"
        Create-KeywordPrefer -AppObject $_ -AppName $AppName -AppCMD $_.CommandLineExecutable -AppArguments $_.CommandLineArguments -DestinationPath $ExportPath
        Create-Shortcut -AppName $AppName -AppCMD $_.CommandLineExecutable -AppArguments $_.CommandLineArguments -DestinationPath $ExportPath
    }
}

If ($Application -and (-not($StudioFolder)))
{
    Write-Output "Starting in application mode"
    Get-BrokerApplication | Where-Object {$_.Name -match $Application} | ForEach-Object {
        Write-Output "Processing application $($_.ApplicationName)"  
        $AppName = $_.ApplicationName -replace ' ','' -replace "\\","-"
        Create-KeywordPrefer -AppObject $_ -AppName $AppName -AppCMD $_.CommandLineExecutable -AppArguments $_.CommandLineArguments -DestinationPath $ExportPath
        Create-Shortcut -AppName $AppName -AppCMD $_.CommandLineExecutable -AppArguments $_.CommandLineArguments -DestinationPath $ExportPath
    }
}

If ($StudioFolder -and (-not($Application)))
{
    Write-Output 'Starting in folder mode'
    Get-BrokerApplication | Where-Object {$_.AdminFolderName -match $StudioFolder} | ForEach-Object {
        Write-Output "Processing application $($_.ApplicationName)"  
        $AppName = $_.ApplicationName -replace ' ','' -replace "\\","-"
        Create-KeywordPrefer -AppObject $_ -AppName $AppName -AppCMD $_.CommandLineExecutable -AppArguments $_.CommandLineArguments -DestinationPath $ExportPath
        Create-Shortcut -AppName $AppName -AppCMD $_.CommandLineExecutable -AppArguments $_.CommandLineArguments -DestinationPath $ExportPath
    }
}




#endregion
