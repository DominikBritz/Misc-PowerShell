Function Test-Admin
{
   PARAM
   (
     [switch]$Verbose,
     [switch]$Debug
   )

   If ($Verbose) { $VerbosePreference = 'Continue' }
   If ($Debug) { $DebugPreference = 'Continue' }

   [int]$BuildNumber = (Get-WmiObject Win32_OperatingSystem | Select-Object BuildNumber).BuildNumber

   Write-Debug "Command line is ___$($MyInvocation.Line)___"
   Write-Verbose 'Entering script body'

   If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator'))
   {
      Write-Verbose 'Script is not run with administrative user'

      If ($BuildNumber -ge 6000)
      {
         Write-Verbose 'Found UAC-enabled system. Elevating ...'

         $CommandLine = $MyInvocation.Line.Replace($MyInvocation.InvocationName, $MyInvocation.MyCommand.Definition)
         Write-Verbose "  $CommandLine"

         Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList "$CommandLine"

      } 
      Else 
      {
         Write-Verbose 'System does not support UAC'
         Write-Warning 'This script requires administrative privileges. Elevation not possible. Please re-run with administrative account.'
      }
      Break
   }
}
