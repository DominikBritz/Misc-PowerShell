$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

<#
.SYNOPSIS
Update MDT deploymentshare and import boot images into WDS
.NOTES
Author: Dominik Britz
www.dominikbritz.com
#>

$ImageNamex64 = 'Lite Touch Windows PE (x64)'
$ImageNamex86 = 'Lite Touch Windows PE (x86)'

$ImageSourcex64 = 'D:\DeploymentShare\Boot\LiteTouchPE_x64.wim'
$ImageSourcex86 = 'D:\DeploymentShare\Boot\LiteTouchPE_x86.wim'

$DeploymentSharePath = 'D:\DeploymentShare'

$MDTModulePath = 'C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1'

Import-Module $MDTModulePath
New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root $DeploymentSharePath
update-MDTDeploymentShare -path "DS001:" -Force -Verbose

Remove-WdsBootImage -ImageName $ImageNamex64 -Architecture x64
Remove-WdsBootImage -ImageName $ImageNamex86 -Architecture x86

Import-WdsBootImage -NewImageName $ImageNamex64 -path $ImageSourcex64
Import-WdsBootImage -NewImageName $ImageNamex86 -path $ImageSourcex86
