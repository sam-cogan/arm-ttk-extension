# arm-ttk-extension
An Azure DevOps Extension for running Azure Resource Manager Template Tool Kit tests as part of your build or release pipeline.

## ARM TTK
The ARM Template Tool Kit is a new static code analyser for ARM templates created by Microsoft. It's an open-source PowerShell library that you can use to validate your templates against a series of test cases. These test cases are generic and designed to validate that your templates are following best practice, a little like the PowerShell PSScriptAnalyzer tool. The ARM TTK tests for:

Templates are using a valid schema
Locations are not hardcoded
Outputs don't contain secrets
ID's are derived from resource ID's
Templates do not contain blanks

## ARM TTK Extension
This extension provides an easy way to run the ARM TTK tests against your templates within Azure DevOps. You could run these tests when you update your template repository, create a pull request against your template repositor or when you are looking to run your templtes to create infrastructure.

### Parameters

This extension expects two paratmers

1. The path to the files you want to test. This can be a folder (all templates in the folder will be tested), a single file, or a path using a wildcard. You do not need to filter out non-templates, the extension will do this for you.
2. The path to output the test results format. This extension outputs the results of all tests in nunit 2 format XML files, one file per file tested. These files use the format "<testFileName>-armttk.xml"

```yaml
- task: RunARMTTKTests@1
  inputs:
    templatelocation: '$(System.DefaultWorkingDirectory)\templates'
    resultLocation: '$(System.DefaultWorkingDirectory)\results'
```

### Test Results

This extension does not publish the tests results to show in the Azure DevOps UI its self, you need to use the "Publish Test Results" extension to read the XML files and publish the results so you can see a test report in the UI. All you need to do is pass the results folder path with a filter looking for armttk results files, e.g:

```yaml
- task: PublishTestResults@2
  inputs:
    testResultsFormat: 'NUnit'
    testResultsFiles: '$(System.DefaultWorkingDirectory)\results\*-armttk.xml'
  condition: always()
```
If any of your tests fail, the RunARMTTKTests task will also fail. To ensure that you always publish your test results make sure you use the ```condition: always()``` setting so this always runs.

Once you do this, Azure DevOps will show the results of your tests in the build.

![Test Results](https://github.com/sam-cogan/arm-ttk-extension/blob/master/images/TestResults.png)

    