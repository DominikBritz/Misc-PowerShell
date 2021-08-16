function Start-Process2([string]$sProcess,[string]$sArgs)
{
    $oProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $oProcessInfo.FileName = $sProcess
    $oProcessInfo.RedirectStandardError = $true
    $oProcessInfo.RedirectStandardOutput = $true
    $oProcessInfo.UseShellExecute = $false
    $oProcessInfo.Arguments = $sArgs
    $oProcess = New-Object System.Diagnostics.Process
    $oProcess.StartInfo = $oProcessInfo
    $oProcess.Start() | Out-Null
    $oProcess.WaitForExit() | Out-Null
    $sSTDOUT = $oProcess.StandardOutput.ReadToEnd()
    
    return $sSTDOUT
}



$Output = @{}



$FindZombieHandlesApp = "$PSScriptRoot\FindZombieHandles\FindZombieHandles.exe"


$Results = Start-Process2 -sProcess $FindZombieHandlesApp -sArgs '-verbose'

If ($Results -match 'XXX')
{
    $Output = @{
       'Zombie' = "`"$Results`""
    }
    Write-Output $($Output.Keys.ForEach({"$_=$($Output.$_)"}) -join ' ')
}

