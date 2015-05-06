<#
    .SYNOPSIS
    Creates a user home and profiledirectory and sets the permissions for the user

    .PARAMETER Username
    The sAMAccountname of the user

    .PARAMETER Domain
    The domain of the user. If nothing is specified, the scripts defaults to the domain of the user who is running the script

    .PARAMETER HomeShare
    The path to the share where the home directory should be created. The share has to exist

    .PARAMETER ProfileShare
    The path to the share where the profile direcotry should be created The share has to exist

    .NOTES
    Author: Dominik Britz
    Source: https://github.com/DominikBritz
#>

[CmdletBinding()]
PARAM
(
    [Parameter(Mandatory=$True,ValidateNotNullOrEmpty)]
    $Username,

    [Parameter(Mandatory=$False)]
    $Domain= $env:USERDOMAIN,

    [Parameter(Mandatory=$False,ValidateNotNullOrEmpty)]
    [ValidateScript({Test-Path $_})]
    $HomeShare,

    [Parameter(Mandatory=$False,ValidateNotNullOrEmpty)]
    [ValidateScript({Test-Path $_})]
    $ProfileShare

)

Function Set-DirAcl
{
    [CmdletBinding()]
    PARAM
    (
        [string]$Username,
        [string]$Domain,
        [string]$Share,
        [string]$AccessRule
    )

    If (-not (Test-Path $(Join-Path $Share $username)))
    {
        New-Item -Path $Share -Name $username -ItemType Directory | out-null
        $acl = Get-Acl $(Join-Path $Share $username)
        $ace = New-Object System.Security.AccessControl.FileSystemAccessRule($AccessRule)
        $acl.AddAccessRule($ace)
        Set-Acl $(Join-Path $Share $username) -AclObject $acl           
    }
    Else
    {
        $acl = Get-Acl $(Join-Path $Share $username)
        $ace = New-Object System.Security.AccessControl.FileSystemAccessRule($AccessRule)
        $acl.AddAccessRule($ace)
        Set-Acl $(Join-Path $Share $username) -AclObject $acl    
    }
}

If ($HomeShare) {
    [string]$AccessRule = "'$domain\$username', 'Modify, Synchronize', 'ContainerInherit, ObjectInherit', 'None', 'Allow'"
    Set-DirAclr -Username $Username -Domain $Domain -Share $HomeShare
}

If ($ProfileShare) {
    [string]$AccessRule = "'$domain\$username', 'Full', 'ContainerInherit, ObjectInherit', 'None', 'Allow'"
    Set-DirAcl -Username $Username -Domain $Domain -Share $ProfileShare -AccessRule $AccessRule
}
