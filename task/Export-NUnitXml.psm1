
Function Export-NUnitXml {
    <#
.SYNOPSIS
    Takes results from ARMTTK and exports them as a Pester test results file (NUnitXml format).
.DESCRIPTION
    Takes results from ARMTTK and exports them as a Pester test results file (NUnit XML schema).
    Because the generated file in NUnit-compatible, it can be consumed and published by most continuous integration tools.
#>
    [CmdletBinding()]
    Param (
        # Object containing all test results
        [Parameter(Mandatory, Position = 0)]
        [AllowNull()]
        [psobject[]]$TestResults,
        # Path to store results
        [Parameter(Mandatory, Position = 1)]
        [string]$Path
    )

    #Validate
    if(-not (Test-Path $Path)){
        New-Item -ItemType Directory -Force -Path $path | Out-Null
    }
    if((Get-Item $Path) -isnot [System.IO.DirectoryInfo]){
        throw "resultLocation must be a folder, not a file"
    }
    
    # Setup variables
    $TotalNumber = If ($TestResults) { $TestResults.Count -as [string] } Else { '1' }
    $FailedNumber = If ($TestResults) { $($TestResults.passed | Where-Object { $_ -eq $false }).count -as [string] } Else { '0' }
    $TotalTime = [math]::Round($($TestResults.TimeSpan | measure-object -Property TotalSeconds -Sum).sum,4).toString()
    $Now = Get-Date
    $FormattedDate = Get-Date $Now -Format 'yyyy-MM-dd'
    $FormattedTime = Get-Date $Now -Format 'HH:mm:ss'
    $User = $env:USERNAME
    $MachineName = $env:COMPUTERNAME
    $Cwd = $pwd.Path
    $UserDomain = $env:USERDOMAIN
    $CurrentCulture = (Get-Culture).Name
    $UICulture = (Get-UICulture).Name
    $OSVersion = (Get-CimInstance Win32_OperatingSystem).version

    Switch ($FailedNumber) {
        0 { $TestResult = 'Success'; $TestSuccess = 'True'; Break }
        Default { $TestResult = 'Failure'; $TestSuccess = 'False' }
    }

    $fileList = $TestResults.file.fullpath | get-unique


  
    #Create seperate XML for each test file
    foreach ($testFile in $fileList) {
   
        # Get test results that are specific to this file
        $splitTestsBody = [string]::Empty
        $filteredTestResults = $testResults | where-object { $_.file.fullpath -eq $testFile }
        $FailedNumber = If ($filteredTestResults) { $($filteredTestResults.passed | Where-Object { $_ -eq $false }).count -as [string] } Else { '0' }
        $TotalNumber = If ($filteredTestResults) { $filteredTestResults.Count -as [string] } Else { '1' }
        Switch ($FailedNumber) {
            0 { $TestResult = 'Success'; $TestSuccess = 'True'; Break }
            Default { $TestResult = 'Failure'; $TestSuccess = 'False' }
        }

        $directoryName = Split-Path (Split-Path $testFile -Parent) -Leaf
        $fileName = Split-Path $testFile -Leaf

        # generate body of XML
        $Header = @"
<?xml version="1.0" encoding="utf-8" standalone="no"?>
    <test-results xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="nunit_schema_2.5.xsd" name="ARMTTK" total="$TotalNumber" errors="0" failures="$FailedNumber" not-run="0" inconclusive="0" ignored="0" skipped="0" invalid="0" date="$FormattedDate" time="$FormattedTime">
        <environment os-version="$OSVersion" user="$User" machine-name="$MachineName" cwd="$Cwd" user-domain="$UserDomain" platform="$Platform" nunit-version="2.5.8.0" clr-version="Unknown"  />
        <culture-info current-culture="$CurrentCulture" current-uiculture="$UICulture" />
        <test-suite type="Powershell" name="ARMTTK" executed="True" result="$TestResult" success="$TestSuccess" time="$TotalTime" asserts="0">
        <results>`n
"@
        
        $Footer = @"
            </results>
          </test-suite>
        </test-results>
"@

        $testHeader = @"
    <test-suite type="TestFixture" name="$directoryName\$fileName" executed="True" result="$TestResult" success="$TestSuccess" time="$TotalTime" asserts="0" description="ARMTTK tests for $fileName">
    <results>`n
"@

        $filterBody = [string]::Empty
        #Generate XML for each test result
        foreach ($result in $filteredTestResults) {   

            $TestCase = [string]::Empty

            if ($result.Passed) {
                $TestCase = @"
    <test-case description="$($result.name) in template file $directoryName\$fileName" name="$($result.name) - $fileName" time="$([math]::Round($result.timespan.TotalSeconds,4).toString())" asserts="0" success="True" result="Success" executed="True">
    </test-case>`n
"@
            }
            else {
                $stacktrace = [System.Security.SecurityElement]::Escape($result.Errors.ScriptStackTrace)
                $TestCase = @"
    <test-case description="$($result.name) in template file $fileName" name="$($result.name) - $fileName" time="$([math]::Round($result.timespan.TotalSeconds,4).toString())" asserts="0" success="False" result="Failure" executed="True">
    <failure>
        <message><![CDATA[$($result.Errors.Exception)]]> in template file $fileName</message>
        <stack-trace><![CDATA[$stacktrace]]></stack-trace>
    </failure>
    </test-case>`n
"@
            }
            $filterBody += $TestCase
        }

        $testFooter = @"
</results>
</test-suite>`n
"@
        #Combine strings to make full result
        $testBody = $testHeader + $filterBody + $testFooter
        $splitTestsBody = $splitTestsBody + $testBody

        # Test XML to make sure it is valid
        $NunitXml = $Header + $splitTestsBody + $Footer

        Try {
            $XmlCheck = [xml]$NunitXml
        }
        Catch {
            Throw "There was an problem when attempting to cast the output to XML : $($_.Exception.Message)"
        }

        $guid = New-Guid
        $NunitXml | Out-File -FilePath "$Path\$($(get-item $testFile).basename)-$($guid)-armttk.xml" -Encoding utf8 -Force
    }
}
