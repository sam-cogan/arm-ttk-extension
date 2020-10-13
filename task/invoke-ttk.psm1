
function Test-FolderContents {
    param(
        [string]$folder,
        [string]$filter,
        [boolean]$createResultsFiles,
        [string[]]$Test,
        [string[]]$Skip
    )
    
    #Path is always set to folder due to limitation of ARMTTK, filter then picks file(s) or full folder to test
    $results = Test-AzTemplate -TemplatePath $folder -File $filter -Skip $Skip -Test $Test -ErrorAction Continue
    if ($createResultsFiles) {
        Export-NUnitXml -TestResults $results -Path $resultlocation
    }

    if (!$results) { 
        return 0
    }
        
    return $($results.passed | Where-Object { $_ -eq $false } | Measure-Object).Count
}

Function Invoke-TTK {
    <#
.SYNOPSIS
    Runs the ARM TTK against the provided test files
#>
    [CmdletBinding()]
    Param (
        # Object containing all test results
        [Parameter(Mandatory, Position = 0)]
        [AllowNull()]
        [string]$templatelocation,
        # Path to store results
        [Parameter(Mandatory, Position = 1)]
        [string]$resultlocation,
        # Whether to create test result files
        [boolean]$createResultsFiles = $true,
        # List of tests to run, if provided will only run these tests
        [Alias('Tests')]
        [string[]]$Test,
        # List of tests to skip
        [string[]]$Skip
    

    )


 


    ### Test Paths
    try {
        $item = Get-Item $templatelocation
    }
    catch {
        Write-Error "Template Location is not an existing folder, file or wildcard"
    }
    #If a folder has been passed in set the template location to a wildcard for that folder
    if ($item -is [System.IO.DirectoryInfo]) {
        $templatelocation = "$($templatelocation.Trimend('\'))\*"
    }
    $files = Get-ChildItem $templatelocation -File -include "*.json", "*.jsonc" -Recurse
    $totalFileCount = $files.count

    if ($totalFileCount -lt 1) {
        Write-Error "No json files found in provided path"
    }

    $FailedNumber = 0
    foreach ($file in $files) {
        $fileInfo = [System.IO.FileInfo]$file    
        $FailedNumber += Test-FolderContents -folder $fileInfo.Directory.FullName -filter $fileInfo.Name -createResultsFiles $createResultsFiles -Test $Test -Skip $Skip
    }

    if ($FailedNumber -gt 0) {
        throw "Failures found in test results"
    }
   

}