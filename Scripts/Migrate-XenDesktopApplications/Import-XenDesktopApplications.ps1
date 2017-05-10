<#
.SYNOPSIS
Imports applications from json files into a Citrix XenDesktop or XenApp 7.8 desktop delivery group

.PARAMETER ImportFolder
Folder where the input json files are located

.PARAMETER DesktopGroup
The Citrix Studio Desktop Delivery Group which will be the target for the import. If the app already exists in a Site the script will just add the DesktopGroup

.EXAMPLE .\Import-XenDesktopApplications.ps1 -Import C:\Import -DesktopGroup ProductionDesktop
Imports all json files from C:\Import to the desktop delivery group "ProductionDesktop" 
#>

Param (
    [Parameter(Position=0,
    Mandatory=$True)]
    [ValidateScript({Test-Path $_})]
	[String]$ImportFolder,

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

Write-Verbose "Check if import folder is empty"
If (-not $(Test-Path $ImportFolder\*.json))
{
	Write-Error "No input JSON files found in folder `"$ImportFolder`". Exiting."
	Exit 1
}
Write-Verbose "Found some json files to work with"

$AttributNames = (Convertfrom-Json "$(Get-Content (Get-ChildItem $ImportFolder -Filter *.json).fullname)"|Get-Member -MemberType NoteProperty|Select-Object Name).name
(Get-ChildItem $ImportFolder -filter *.json).FullName|ForEach-Object{
    $BrokerApplicationJSONFile = ConvertFrom-Json "$(Get-Content $_)"
    $BrokerApplicationHashTable = @{}
    $BrokerApplicationJSONFile|get-member -MemberType NoteProperty|Where-Object{-not [string]::IsNullOrEmpty($BrokerApplicationJSONFile."$($_.name)")}|ForEach-Object {$BrokerApplicationHashTable.add($_.name,$BrokerApplicationJSONFile."$($_.name)")}
    $AttributNames|ForEach-Object{        
        if($_ -match 'AdminFolderUid' -or $_ -match 'AssociatedDesktopGroupUUIDs' -or $_ -match 'EncodedIcon')
        {
            $BrokerApplicationHashTable.Remove("$_")
        }        
    }    

    $OldAppName = $BrokerApplicationHashTable.Name #save the full name with possible admin folders for later use as we have to trim all backspaces because studio does not allow them on app creation
    
    If (Get-BrokerApplication $OldAppName -ErrorAction SilentlyContinue)
    {
        Write-Verbose "App $OldAppName already exists. Skipping..."
    }
    Else
    {
        Write-Verbose "Check if app has admin folder configured"
        If ($BrokerApplicationHashTable.AdminFolderName)
        {
            $Folder = $BrokerApplicationHashTable.AdminFolderName
            Write-Verbose "Admin folder $Folder configured"
            If ($Folder.Split('\').Count -eq 1) #only one folder level
            {
                $FolderName = $Folder.Split('\')[0]
                If (Get-BrokerAdminFolder -Name $Folder -ErrorAction SilentlyContinue)
                {
                    Write-Verbose "Admin folder $Folder already exists. Skipping..."
                }
                Else
                {
                    Write-Verbose "Create admin folder $FolderName" 
                    $null = New-BrokerAdminFolder -FolderName $FolderName
                }
            }
            Else #multiple folder levels
            {
                $max = $Folder.Split('\').Count - 1
                for ($i = 0; $i -le $max; $i++)
                {
                    If ($i -eq 0) #root folder does not exist
                    {
                        $FolderName = $Folder.Split('\')[0]
                        If (Get-BrokerAdminFolder -Name $Folder -ErrorAction SilentlyContinue)
                        {
                            Write-Verbose "Admin folder $Folder already exists. Skipping..."
                        }
                        Else
                        {
                            Write-Verbose "Create admin folder $FolderName" 
                            $null = New-BrokerAdminFolder -FolderName $FolderName
                        }
                    }
                    Else #root folder already exists
                    {
                        $FolderName = $Folder.Split('\')[$i]
                        $ParentFolder = ($Folder.SubString(0, $Folder.LastIndexOf("$FolderName"))).Trim('\')
                        If (Get-BrokerAdminFolder -Name $Folder -ErrorAction SilentlyContinue)
                        {
                            Write-Verbose "Admin folder $Folder already exists. Skipping..."
                        }
                        Else
                        {
                            Write-Verbose "Create admin folder $FolderName in parent folder $ParentFolder"
                            $null = New-BrokerAdminFolder -FolderName $FolderName -ParentFolder $ParentFolder
                        }
                    }
                }
            }
        }
        

        $BrokerApplicationHashTable.Name = $BrokerApplicationHashTable.Name.Split('\')[-1]
        $BrokerApplicationHashTable.CommandLineArguments = $BrokerApplicationHashTable.CommandLineArguments -replace '"%\*"','' -replace "`"","'"
    
        $MakeApp = 'New-BrokerApplication -ApplicationType HostedOnDesktop'
        if($BrokerApplicationHashTable.Name -ne $null){$MakeApp += " -Name `"$($BrokerApplicationHashTable.Name)`""}
        if($BrokerApplicationHashTable.BrowserName -ne $null){$MakeApp += " -BrowserName `"$($BrokerApplicationHashTable.BrowserName)`""}
        if($BrokerApplicationHashTable.CommandLineExecutable -ne $null){$MakeApp += " -CommandLineExecutable `"$($BrokerApplicationHashTable.CommandLineExecutable)`""}
        if($BrokerApplicationHashTable.Description -ne $null){$MakeApp += " -Description `"$($BrokerApplicationHashTable.Description)`""}
        if($BrokerApplicationHashTable.ClientFolder -ne $null){$MakeApp += " -ClientFolder `"$($BrokerApplicationHashTable.ClientFolder)`""}
        if($BrokerApplicationHashTable.CommandLineArguments -ne ""){$MakeApp += " -CommandLineArguments `"$($BrokerApplicationHashTable.CommandLineArguments)`""}        
        if($BrokerApplicationHashTable.Enabled -ne $null){$MakeApp += " -Enabled `$$($BrokerApplicationHashTable.Enabled)"}    
        if($BrokerApplicationHashTable.WorkingDirectory -ne $null){$MakeApp += " -WorkingDirectory `"$($BrokerApplicationHashTable.WorkingDirectory)`""}
        if($BrokerApplicationHashTable.PublishedName -ne $null){$MakeApp += " -PublishedName `"$($BrokerApplicationHashTable.PublishedName)`""}
        if($BrokerApplicationHashTable.AdminFolderName -ne $null){$MakeApp += " -AdminFolder `"$($BrokerApplicationHashTable.AdminFolderName)`""}
        if($BrokerApplicationHashTable.WaitForPrinterCreation -ne $null){$MakeApp += " -WaitForPrinterCreation `$$($BrokerApplicationHashTable.WaitForPrinterCreation)"}
        if($BrokerApplicationHashTable.StartMenuFolder -ne $null){$MakeApp += " -StartMenuFolder `"$($BrokerApplicationHashTable.StartMenuFolder)`""}        
        if($BrokerApplicationHashTable.ShortcutAddedToStartMenu -ne $null){$MakeApp += " -ShortcutAddedToStartMenu `$$($BrokerApplicationHashTable.ShortcutAddedToStartMenu)"}
        if($BrokerApplicationHashTable.ShortcutAddedToDesktop -ne $null){$MakeApp += " -ShortcutAddedToDesktop `$$($BrokerApplicationHashTable.ShortcutAddedToDesktop)"}
        if($BrokerApplicationHashTable.Visible -ne $null){$MakeApp += " -Visible `$$($BrokerApplicationHashTable.Visible)"}
        if($BrokerApplicationHashTable.SecureCmdLineArgumentsEnabled -ne $null){$MakeApp += " -SecureCmdLineArgumentsEnabled `$$($BrokerApplicationHashTable.SecureCmdLineArgumentsEnabled)"}        
        if($BrokerApplicationHashTable.MaxTotalInstances -ne $null){$MakeApp += " -MaxTotalInstances $($BrokerApplicationHashTable.MaxTotalInstances)"}        
        if($BrokerApplicationHashTable.CpuPriorityLevel -ne $null){$MakeApp += " -CpuPriorityLevel $($BrokerApplicationHashTable.CpuPriorityLevel)"}
        if($BrokerApplicationHashTable.Tags -ne $null){$MakeApp += " -Tags `"$($BrokerApplicationHashTable.Tags)`""}
        if($BrokerApplicationHashTable.MaxPerUserInstances -ne $null){$MakeApp += " -MaxPerUserInstances $($BrokerApplicationHashTable.MaxPerUserInstances)"}
        
        $MakeApp += " -DesktopGroup `"$DesktopGroup`""
            
        Write-Verbose "Create app $($BrokerApplicationHashTable.Name) with command $MakeApp"
        Invoke-Expression $MakeApp | Out-Null #we cant use splatting as the cmdlet New-BrokerApplication can not deal with empty values
    
        $EncodedIcon = New-BrokerIcon -EncodedIconData "$($BrokerApplicationJSONFile.EncodedIconData)"
        Set-BrokerApplication -Name "$OldAppName"  -IconUid $EncodedIcon.Uid

        If($BrokerApplicationHashTable.AssociatedUserNames -ne $null)
        {
            Set-BrokerApplication -Name "$OldAppName" -UserFilterEnabled $true          
            $users = $BrokerApplicationHashTable.AssociatedUserNames 
            foreach($user in $users)
            {
                Write-Verbose "Add user $user to app $OldAppName"
                Add-BrokerUser -Name $user -Application "$OldAppName"
            }            
        }

        Write-Verbose "Check if app $OldAppName has FTAs configured"
        $AttributNames | where-object {$_ -match 'FTA-'} | ForEach-Object {
            $OldFTA = $BrokerApplicationHashTable.$_
            
            $MakeFTA = "New-BrokerConfiguredFTA -ApplicationUid $((Get-brokerapplication -Name $OldAppName).Uid)"
            if($OldFTA.ExtensionName -ne $null){$MakeFTA += " -ExtensionName `"$($OldFTA.ExtensionName)`""}
            if($OldFTA.ContentType -ne $null){$MakeFTA += " -ContentType `"$($OldFTA.ContentType)`""}
            if($OldFTA.HandlerOpenArguments -ne $null){$MakeFTA += " -HandlerOpenArguments `"$($OldFTA.HandlerOpenArguments)`""}
            if($OldFTA.HandlerDescription -ne $null){$MakeFTA += " -HandlerDescription `"$($OldFTA.HandlerDescription)`""}
            if($OldFTA.HandlerName -ne $null){$MakeFTA += " -HandlerName `"$($OldFTA.HandlerName)`""}
            
            Write-Verbose "Create FTA $($OldFTA.ExtensionName) for app $OldAppName with command $MakeFTA"
            Invoke-Expression $MakeFTA | Out-Null #we cant use splatting as the cmdlet New-BrokerConfiguredFTA can not deal with empty values    
        }
    }
}

Write-Verbose 'Finished'

#endregion