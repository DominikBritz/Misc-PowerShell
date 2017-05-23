#Requires -Version 3
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

<#
.SYNOPSIS
This is a template for PowerShell scripts and functions
.NOTES
Author: Dominik Britz
www.dominikbritz.com
#>

#region Script Variables

#endregion

#region Functions
function Verb-Noun
{
    <#
    .SYNOPSIS
    Short description
    .DESCRIPTION
    Long description
    .PARAMETER Test
    Description of Parameter Test
    .EXAMPLE
    Example of how to use this cmdlet
    .EXAMPLE
    Another example of how to use this cmdlet
    .INPUTS
    Inputs to this cmdlet (if any)
    .OUTPUTS
    Output from this cmdlet (if any)
    .NOTES
    Author: Dominik Britz
    www.dominikbritz.com
    #>
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1')]
    [Alias()]
    [OutputType([String])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parameter Set 1')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateCount(0,5)]
        [ValidateSet('sun', 'moon', 'earth')]
        [Alias('p1')] 
        $Param1,

        # Param2 help description
        [Parameter(ParameterSetName='Parameter Set 1')]
        [AllowNull()]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [ValidateScript({$true})]
        [ValidateRange(0,5)]
        [int]
        $Param2,

        # Param3 help description
        [Parameter(ParameterSetName='Another Parameter Set')]
        [ValidatePattern('[a-z]*')]
        [ValidateLength(0,15)]
        [String]
        $Param3
    )

    Begin
    {
        Try
        {
        
        }
        Catch
        {
        
        }
    }

    Process
    {
        Try
        {
        
        }
        Catch
        {
        
        }
    }

    End
    {

    }
}

function Test-Admin
{
param(
  [switch]$Verbose,
  [switch]$Debug
)

if ($Verbose) { $VerbosePreference = 'Continue' }
if ($Debug) { $DebugPreference = 'Continue' }

Write-Debug "Command line is ___$($MyInvocation.Line)___"
Write-Verbose 'Entering script body'

If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
  Write-Verbose 'Script is not run with administrative user'

  If ((Get-WmiObject Win32_OperatingSystem | Select-Object BuildNumber).BuildNumber -ge 6000) {
    Write-Verbose 'Found UAC-enabled system. Elevating ...'

    $CommandLine = $MyInvocation.Line.Replace($MyInvocation.InvocationName, $MyInvocation.MyCommand.Definition)
    Write-Verbose "  $CommandLine"
 
    Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList "$CommandLine"

  } else {
    Write-Verbose 'System does not support UAC'
    Write-Warning 'This script requires administrative privileges. Elevation not possible. Please re-run with administrative account.'
  }
  Break
}

}

#endregion

#region Main
Test-Admin -Verbose

#endregion
