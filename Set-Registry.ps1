Function Set-Registry
{
    [CmdletBinding()]
    PARAM
    (
        $RegKey,
        $RegValue,
        $RegData,
        [ValidateSet('String','DWord','Binary','ExpandString','MultiString','None','QWord','Unknown')]
        $RegType    
    )

    If (-not $RegValue)
    {
        If (-not (Test-Path $RegKey))
        {
                New-Item -Path $RegKey -Force
        }
    }

    If ($RegValue)
    {
        If (-not (Test-Path $RegKey))
        {
            New-Item -Path $RegKey -Force
            Set-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -Type $RegType -Force
        }
        Else 
        {
            Set-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -Type $RegType -Force
        }
    }
}
