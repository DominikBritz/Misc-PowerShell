<#
    .SYNOPSIS
    Creates a user home and profiledirectory and sets the permissions for the user

    .PARAMETER Username
    The sAMAccountname of the user. Input from pipeline is permitted

    .PARAMETER Domain
    The domain of the user. If nothing is specified, the scripts defaults to the domain of the user who is running the script

    .PARAMETER HomeShare
    The path to the share where the home directory should be created. The share has to exist

    .PARAMETER ProfileShare
    The path to the share where the profile direcotry should be created The share has to exist

    .PARAMETER Force
    Deletes all existing permissions of the user. Needs to be $true or $false

    .NOTES
    Author: Dominik Britz
    Source: https://github.com/DominikBritz
#>

[CmdletBinding()]
PARAM
(
    [Parameter(Mandatory=$True,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Username,

    [Parameter(Mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [string]$Domain= $env:USERDOMAIN,

    [Parameter(Mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path $_})]
    [string]$HomeShare,

    [Parameter(Mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path $_})]
    [string]$ProfileShare,

    [Parameter(Mandatory=$False)]
    [ValidateNotNullOrEmpty()]    
    [bool]$Force = $False

)

Begin{}
Process{
Function Set-DirAcl
{
    [CmdletBinding()]
    PARAM
    (
        [string]$Username,
        [string]$Domain,
        [string]$Share,
        $AccessRule,
        [bool]$Force
    )

    If (-not (Test-Path $(Join-Path $Share $username)))
    {
        try
        {
            Write-Verbose "The directory $(Join-Path $Share $username) does not exist. Create it."
            New-Item -Path $Share -Name $username -ItemType Directory
            Write-Verbose "Directory $(Join-Path $Share $username) successfully created"

            Write-Verbose "Set permissions"
            $acl = Get-Acl $(Join-Path $Share $username)
            $ace = New-Object System.Security.AccessControl.FileSystemAccessRule $AccessRule
            $acl.AddAccessRule($ace)
            Set-Acl $(Join-Path $Share $username) -AclObject $acl
            Write-Verbose "Permission successfully set"
        }        
        catch 
        {
            Write-Error $_.Exception.Message
        }                  
    }
    Else
    {
        try
        {
            Write-Verbose "The directory $(Join-Path $Share $username) already exists"
            Write-Verbose "Set permissions"
            $acl = Get-Acl $(Join-Path $Share $username)
            $AlreadyPermissions = $False
            Foreach ($item in $acl.Access)
            {
                If ($item.IdentityReference.Value -eq "$domain\$username")
                {
                    $AlreadyPermissions = $True
                    If ($Force)
                    {
                        $acl.RemoveAccessRule($item)
                        $AlreadyPermissions = $False
                    } 
                }
            }
            If (-not $AlreadyPermissions)
            {
                $ace = New-Object System.Security.AccessControl.FileSystemAccessRule $AccessRule
                $acl.AddAccessRule($ace)
            }
            Set-Acl $(Join-Path $Share $username) -AclObject $acl
        }
        catch
        {
            Write-Error $_.Exception.Message        
        }
    }
}

If ($HomeShare) {
    Write-Verbose "Processing home directory for user $Username at $HomeShare"
    $AccessRule = "$domain\$username", 'Modify, Synchronize', 'ContainerInherit, ObjectInherit', 'None', 'Allow'
    Set-DirAcl -Username $Username -Domain $Domain -Share $HomeShare -AccessRule $AccessRule -Force $Force
}

If ($ProfileShare) {
    Write-Verbose "Processing profile directory for user $Username at $ProfileShare"
    $AccessRule = "$domain\$username", 'Full', 'ContainerInherit, ObjectInherit', 'None', 'Allow'
    Set-DirAcl -Username $Username -Domain $Domain -Share $ProfileShare -AccessRule $AccessRule -Force $Force
}
}

End{}
