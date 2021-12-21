
BeforeAll {

$here = split-path $PSCommandPath -Parent
$invokeScript = "$here\..\task\invoke-ttk.psm1"
$exportScript = "$here\..\task\Export-NUnitXml.psm1"


Import-Module "$here\..\task\arm-ttk\arm-ttk.psd1"
Import-Module "$here\..\task\Export-NUnitXml.psm1"
Import-Module "$here\..\task\invoke-ttk.psm1"
}

Describe "File Test" {
    it " includes an invoke-ttk.psm1 file" {
        $invokeScript | should -Exist
    }

    it "includes an Export-NUnitXml.psm1 file" {
        $exportScript | should -Exist
    }

    it "includes an  arm-ttk folder" {
        "$here\..\task\arm-ttk" | should -Exist
    }
}

describe "Single File Tests" {
    BeforeAll{
    $testPath = "TestDrive:\"
    $goodFile= "$herec"
    $badFile = "$here\testfiles\single-file\bad-test.json" 
    }

    it "should generate no errors for a valid file"{
        Invoke-TTK -templatelocation $goodFile  -resultlocation $testPath -createResultsFiles $false | should -BeNullOrEmpty
    }

    it "should generate errors for an invalid file"{
        {Invoke-TTK -templatelocation $badFile  -resultlocation $testPath -createResultsFiles $false }| Should -Throw "Failures found in test results"
    }

    it "generates a single results file"{
        Invoke-TTK -templatelocation $goodFile  -resultlocation "$testPath"
        $(Get-ChildItem $testPath).count |  should -be 1
    }

    it "generates a results file with the correct name"{
        $hash = Get-FileHash -Path $goodFile -Algorithm MD5
        Invoke-TTK -templatelocation $goodFile  -resultlocation "$testPath"
        $(Get-ChildItem $testPath)[0].name |  should -be "$($(get-item $goodFile ).basename)-$($hash.Hash)-armttk.xml"
    }

    it "should test only the named tests when 'Test' is provided"{
        Invoke-TTK -templatelocation $goodFile  -resultlocation $testPath -createResultsFiles $true -Test @("VM Images Should Use Latest Version")
        $hash = Get-FileHash -Path $goodFile -Algorithm MD5
        [xml]$resultdoc = Get-Content "$testPath\$($(get-item $goodFile ).basename)-$($hash.Hash)-armttk.xml"
        $testcases  = @($resultdoc."test-results"."test-suite".results."test-suite".results."test-case")
        $testcases.Count | should -be 1 
        $testcases[0].name | should -be "VM Images Should Use Latest Version - good-test.json"
    }

    it "should skip tests when the skip value is provided" {
        $hash = Get-FileHash -Path $goodFile -Algorithm MD5

        Invoke-TTK -templatelocation $goodFile  -resultlocation $testPath -createResultsFiles $true 
        [xml]$resultdoc = Get-Content "$testPath\$($(get-item $goodFile ).basename)-$($hash.Hash)-armttk.xml"
        $testcases  = @($resultdoc."test-results"."test-suite".results."test-suite".results."test-case")
        $fullCount = $testcases.Count 

        Invoke-TTK -templatelocation $goodFile  -resultlocation $testPath -createResultsFiles $true -Skip @("VM Images Should Use Latest Version")
        [xml]$resultdoc = Get-Content "$testPath\$($(get-item $goodFile ).basename)-$($hash.Hash)-armttk.xml"
        $testcases  = @($resultdoc."test-results"."test-suite".results."test-suite".results."test-case")
        $skipCount = $testcases.Count 

        $skipCount | should -be ($fullCount - 1)
        $testcases.name | should -Not -Contain "VM Images Should Use Latest Version - good-test.json"
        
    }

}

# describe "jsonc c test" {
#     $testPath = "TestDrive:\"
#     $goodFile= "$here\testfiles\single-file\good-test.jsonc"
#     $badFile = "$here\testfiles\single-file\bad-test.jsonc" 

#     it "should generate no errors for a valid file"{
#         Invoke-TTK -templatelocation $goodFile  -resultlocation $testPath -createResultsFiles $false | should -BeNullOrEmpty
#     }

#     it "should generate errors for an invalid file"{
#         {Invoke-TTK -templatelocation $badFile  -resultlocation $testPath -createResultsFiles $false }| Should -Throw "Failures found in test results"
#     }
# }

describe "multiple file tests"{
    BeforeAll{
    $testPath = "TestDrive:\"
    }

    it "generates a results file per template"{
        try{
        Invoke-TTK -templatelocation "$here\testfiles\multiple-files"  -resultlocation "$testPath"
        }
        catch{
            $_.Exception.Message | should -be "Failures found in test results"
        }
        finally{
            Get-ChildItem $testPath
            $(Get-ChildItem $testPath).count |  should -be 7
        }

    }


}

describe "folder with period"{
       BeforeAll{
    $testPath = "TestDrive:\"
    }


    it "runs tests sucessfully"{
        Invoke-TTK -templatelocation "$here\testfiles\dot.folder"  -resultlocation $testPath 
        $(Get-ChildItem $testPath).count |  should -be 1
    }
}

describe "Message with HTML"{
       BeforeAll{
    $testPath = "TestDrive:\"
    }


    it "creates export file"{
        try{
        Invoke-TTK -templatelocation "$here\testfiles\encoding"  -resultlocation $testPath 
        }
        Catch{}
        $(Get-ChildItem $testPath).count |  should -be 1
    }
}

describe "Setting Main Template"{
       BeforeAll{
    $testPath = "TestDrive:\"
    }


    it "has no errors when main template is set"{
        
        Invoke-TTK -templatelocation "$here\testfiles\mainTemplate" -mainTemplates @("newStorageAccount.json")  -resultlocation $testPath | should -BeNullOrEmpty
      
    }

     it "has errors when main template is not set"{
        
        {Invoke-TTK -templatelocation "$here\testfiles\mainTemplate"   -resultlocation $testPath} | Should -Throw "Failures found in test results"
      
    }
}

describe "bicep file tests"{
    BeforeAll{
    $testPath = "TestDrive:\"
    }
 write-host "$here"
    it "has generated the correct result files"{

        
   try{
        Invoke-TTK -templatelocation "$here\testfiles\bicep"  -resultlocation "$testPath"
        }
        catch{
            $_.Exception.Message | should -be "Failures found in test results"
        }
        finally{
            Get-ChildItem $testPath
            $(Get-ChildItem $testPath).count |  should -be 2
        }

    }

}