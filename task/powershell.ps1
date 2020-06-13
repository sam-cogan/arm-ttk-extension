[CmdletBinding()] 
param() 
 
Import-Module "$PSScriptRoot\arm-ttk\arm-ttk.psd1"
Import-Module "$PSScriptRoot\Export-NUnitXml.psm1"
Import-Module "$PSScriptRoot\invoke-ttk.psm1"

$templatelocation =  get-VstsInput -Name templatelocation -Require
$resultlocation =    get-VstsInput -Name resultLocation -Require
$TestString =    get-VstsInput -Name includeTests
$SkipString =    get-VstsInput -Name skipTests

if($TestString){
    $Test=$TestString.split(',')
}
else{
    $Test =@()
}

if($SkipString){
    $Skip=$SkipString.split(',')
}
else{
    $Skip =@()
}


Invoke-TTK -templatelocation $templatelocation  -resultlocation $resultlocation -Test $Test -Skip $Skip