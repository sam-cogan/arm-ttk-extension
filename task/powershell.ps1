[CmdletBinding()] 
param() 
 
Import-Module "$PSScriptRoot\arm-ttk\arm-ttk.psd1"
Import-Module "$PSScriptRoot\Export-NUnitXml.psm1"
Import-Module "$PSScriptRoot\invoke-ttk.psm1"
write-host "host: $PSScriptRoot"
$templatelocation =  get-VstsInput -Name templatelocation -Require
$resultlocation =    get-VstsInput -Name resultLocation -Require
$TestString =    get-VstsInput -Name includeTests
$SkipString =    get-VstsInput -Name skipTests
$mainTemplateString = get-VstsInput -Name mainTemplates
[boolean]$allTemplatesAreMain = get-VstsInput -Name allTemplatesMain -AsBool
[boolean]$cliOutputResults = get-VstsInput -Name cliOutputResults -AsBool


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

if($mainTemplateString){
    $mainTemplates=$mainTemplateString.split(',')
}
else{
    $mainTemplates =@()
}


Invoke-TTK -templatelocation $templatelocation  -resultlocation $resultlocation -Test $Test -Skip $Skip -mainTemplates $mainTemplates -allTemplatesAreMain $allTemplatesAreMain -cliOutputResults $cliOutputResults