[CmdletBinding()] 
param() 
 
Import-Module "$PSScriptRoot\arm-ttk\arm-ttk.psd1"
Import-Module "$PSScriptRoot\Export-NUnitXml.ps1"

$templatelocation = get-VstsInput -Name templatelocation -Require
$resultlocation = get-VstsInput -Name resultLocation -Require

function Test-FolderContents {
    param(
        [string]$folder,
        [string]$filter
    )
    
    #Path is always set to folder due to limitation of ARMTTK, filter then picks file(s) or full folder to test
    $results = Test-AzTemplate -TemplatePath $folder -File $filter -ErrorAction Continue
    Export-NUnitXml -TestResults $results -Path $resultlocation

    if (!$results) { 
        return 0
    }
        
    return $($results.passed | Where-Object { $_ -eq $false } | Measure-Object).Count
}

### Test Paths
try {
    $item = Get-Item $templatelocation
}
catch {
    Write-Error "Template Location is not an existing folder, file or wildcard"
}
#If a folder has been passed in set the template location to a wildcard for that folder
if ($item -is [System.IO.DirectoryInfo]){
    $templatelocation = "$($templatelocation.Trimend('\'))\*"
}

$files = Get-ChildItem $templatelocation -File -Filter "*.json" -Recurse
$totalFileCount = $files.count

if ($totalFileCount -lt 1) {
    Write-Error "No json files found in provided path"
}

$FailedNumber = 0
foreach ($file in $files) {
    $fileInfo = [System.IO.FileInfo]$file    
    $FailedNumber += Test-FolderContents -folder $fileInfo.Directory.FullName -filter $fileInfo.Name
}

if ($FailedNumber -gt 0) {
    throw "Failures found in test results"
}
