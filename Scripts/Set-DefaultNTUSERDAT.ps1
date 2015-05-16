Function Set-DefaultNTUSERDAT
{
    <#
    .SYNOPSIS
    With this function you can load or unload the default ntuser.dat of the local system

    .PARAMETER Load
    When this parameter is set, the script will load the default ntuser.dat

    .PARAMETER Unload
    When this parameter is set, the script will unload the default ntuser.dat

    .PARAMETER Path
    Specifies a path in the local registry where the default ntuser.dat should be loaded. E.g. HKCU:\DEFAULT
    Default is HKCU:\DEFAULT
    
    .EXAMPLE
    Set-DefaultNUTSERDAT -Load -Path HKCU:\_TEMP\DEFAULT
    Loads the default NTUSER.DAT to the path HKCU\_TEMP\DEFAULT
    
    .EXAMPLE
    Set-DefaultNTUSERDAT -Unload
    Unloads the default NTUSER.DAT from HKCU\DEFAULT

    .NOTES
    Author: Dominik Britz
    Link: https://github.com/DominikBritz
    #>
    [CmdletBinding()]
    PARAM
    (
        [ValidateScript({
                If (Test-Path $_) {
                    Write-Error "The path $_ already exists. Loading not possible."
                    Exit
                }
        })]
        [switch]$Load,
        [switch]$Unload,
        [string]$Path='HKCU:\DEFAULT'
    )

    If ($Load -and $Unload) 
    {
        Write-Error 'You can not call this function with both Load and Unload parameters'
        Exit
    }

    $CMDPath = $Path -replace ':',''

    If ($Load)
    {
        Start-Process -FilePath REG.EXE -ArgumentList "LOAD $CMDPath C:\Users\Default\NTUSER.DAT"
        $i = 1
        While (-not(Test-Path $Path))
        {
            Write-Verbose "This is the $i loop while waiting for the default hive to appear"
            Write-Verbose 'Go to sleep now for 3 seconds'
            Start-Sleep -Seconds 3
            $i++
        }
        Write-Verbose 'The default hive is now loaded'
    }

    If ($Unload) 
    {
        0 | Out-Null # http://stackoverflow.com/questions/25438409/reg-unload-and-new-key
        [gc]::Collect()
        Start-Sleep -Seconds 5
        Start-Process -FilePath REG.EXE -ArgumentList "UNLOAD $CMDPath"
        $i = 1
        While (Test-Path $Path)
        {
            Write-Verbose "This is the $i loop while waiting for the default hive to disappear"
            Write-Verbose 'Go to sleep now for 3 seconds'
            Start-Sleep -Seconds 3
            $i++
        }
        Write-Verbose 'The default hive is now unloaded'
    }
}
