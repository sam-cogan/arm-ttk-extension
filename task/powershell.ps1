[CmdletBinding()] 
param() 
 
$ScriptDir = Split-Path -parent $MyInvocation.MyCommand.Path
Import-Module "$ScriptDir\arm-ttk\arm-ttk.psd1"
Import-Module "$ScriptDir\Export-NUnitXml.ps1"

$templatelocation = get-VstsInput -Name templatelocation -Require
$resultlocation = get-VstsInput -Name resultLocation -Require

### Test Paths
try{
    Get-Item $templatelocation
}
catch{
    write-error "Template Location is not an existing folder, file or wildcard"
}
#If a folder has been passed in set the template location to a wildcard for that folder
if((Get-Item $templatelocation) -is [System.IO.DirectoryInfo]){
    $templatelocation = "$($templatelocation.Trimend('\'))\*"
}

$totalFileCount = $(Get-ChildItem $templatelocation).count

if($totalFileCount -lt 1){
    Write-Error "No files found in provided path"
}

### Run Tests
$folder = split-path $templatelocation
$filter = split-path $templatelocation -leaf
#Path is always set to folder due to limitation of ARMTTK, filter then picks file(s) or full folder to test
$results=Test-AzTemplate -TemplatePath "$folder" -File "$filter" -ErrorAction Continue
Export-NUnitXml -TestResults $results  -Path $resultlocation

$FailedNumber = If ($results) { $($results.passed | Where-Object { $_ -eq $false }).count -as [string] } Else { '0' }
if($FailedNumber -gt 0){
    throw "Failures found in test results"
}
