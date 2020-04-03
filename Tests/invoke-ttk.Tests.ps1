$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$invokeScript = "$here\..\task\invoke-ttk.psm1"
$exportScript = "$here\..\task\Export-NUnitXml.psm1"

Import-Module "$here\..\task\arm-ttk\arm-ttk.psd1"
Import-Module "$here\..\task\Export-NUnitXml.psm1"
Import-Module "$here\..\task\invoke-ttk.psm1"


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
    $testPath = "TestDrive:\"
    $goodFile= "$here\testfiles\single-file\good-test.json"
    $badFile = "$here\testfiles\single-file\bad-test.json" 

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
}

describe "multiple file tests"{
    $testPath = "TestDrive:\"

    it "generates a results file per template"{
        try{
        Invoke-TTK -templatelocation "$here\testfiles\multiple-files"  -resultlocation "$testPath"
        }
        catch{
            $_.Exception.Message | should -be "Failures found in test results"
        }
        finally{
            Get-ChildItem $testPath
            $(Get-ChildItem $testPath).count |  should -be 5
        }

    }

    it "does not generate a results file for a paramters file"{
        $paramFile="$here\testfiles\multiple-files\CrossSubscriptionDeployments.parameters.json"
        $hash = Get-FileHash -Path $paramFile -Algorithm MD5
        $(Get-ChildItem $testPath).name | should -not -contain "CrossSubscriptionDeployments.parameters-$($hash.Hash)-armttk.xml"
    }

}

describe "folder with period"{
    $testPath = "TestDrive:\"

    it "runs tests sucessfully"{
        Invoke-TTK -templatelocation "$here\testFiles\dot.folder"  -resultlocation $testPath -createResultsFiles $false | should -BeNullOrEmpty
    }
}

