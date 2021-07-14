
function Test-FolderContents {
    param(
        [string]$folder,
        [string]$filter,
        [boolean]$createResultsFiles,
        [string[]]$Test,
        [string[]]$Skip,
        [boolean]$mainTemplate,
        [boolean]$ignoreExitCode
    )
    
    #Path is always set to folder due to limitation of ARMTTK, filter then picks file(s) or full folder to test
    if ($mainTemplate) {
        $results = Test-AzTemplate -TemplatePath $folder -File $filter -Skip $Skip -Test $Test -mainTemplate $filter -ErrorAction  Continue
    }
    else {
        $results = Test-AzTemplate -TemplatePath $folder -File $filter -Skip $Skip -Test $Test -ErrorAction Continue
    }
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
        [string[]]$Skip,
        # List of files to treat as main templates
        [string[]]$MainTemplates,
        # treat all templates as main template
        [boolean]$allTemplatesAreMain = $false,
        # Whether to provide summary outputs at the CLI
        [boolean]$cliOutputResults = $false

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


    $bicepFiles = Get-ChildItem $templatelocation -include "*.bicep" -Recurse

    if($bicepFiles.count -gt 0){
        if ((Get-Command "bicep.exe" -ErrorAction SilentlyContinue) -eq $null -and (Get-Command "$PSScriptRoot\bicep.exe" -ErrorAction SilentlyContinue) -eq $null) {
        write-Host "Bicep Not Found, Downloading..."
        (New-Object Net.WebClient).DownloadFile("https://github.com/Azure/bicep/releases/latest/download/bicep-win-x64.exe", "$PSScriptRoot\bicep.exe")
        }
        foreach($bicepFile in $bicepFiles){
            & "$PSScriptRoot\bicep.exe" build $bicepFile
        }
    }

    $files = Get-ChildItem $templatelocation -include "*.json", "*.jsonc" -Recurse
    $totalFileCount = $files.count

    if ($totalFileCount -lt 1) {
        Write-Error "No json files found in provided path"
    }

    $FailedNumber = 0
    foreach ($file in $files) {
        $fileInfo = [System.IO.FileInfo]$file    
        $mainTemplate = $false
        if (($mainTemplates -contains $fileInfo.name) -or $allTemplatesAreMain) {
            $mainTemplate = $true    
        }
        #hack to skip this test temporarily, as it causes errors in PowerShell 5
        $skip = $skip += "Secure-Params-In-Nested-Deployments"
        $failedTests = Test-FolderContents -folder $fileInfo.Directory.FullName -filter $fileInfo.Name -createResultsFiles $createResultsFiles -Test $Test -Skip $Skip -mainTemplate $mainTemplate
        $FailedNumber += $failedTests
        if ($cliOutputResults) {
            if ($failedTests -gt 0) {
                Write-Host "##[warning] $file failed $failedTests test"
            }
            else {
                Write-Host "##[section] $file passed all tests" -ForegroundColor Green
            }
        }
    }

    if ($FailedNumber -gt 0)  {
        if($ignoreExitCode){
            write-host "Failures found in test results but ignoring exit code"
        }
        else {
            throw "Failures found in test results"
        }
        
        
    }
    
    
}