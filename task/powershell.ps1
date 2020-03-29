[CmdletBinding()] 
param() 
 
Import-Module "$PSScriptRoot\arm-ttk\arm-ttk.psd1"
Import-Module "$PSScriptRoot\Export-NUnitXml.psm1"
Import-Module "$PSScriptRoot\invoke-ttk.psm1"

$templatelocation =  get-VstsInput -Name templatelocation -Require
$resultlocation =    get-VstsInput -Name resultLocation -Require


Invoke-TTK -templatelocation $templatelocation  -resultlocation $resultlocation