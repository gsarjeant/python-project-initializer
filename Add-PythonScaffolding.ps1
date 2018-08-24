<#
.SYNOPSIS
Add-PythonScaffolding

This script verifies that the system has necessary prerequisites for python development
and sets up python development scaffolding in a target project directory.
.DESCRIPTION
First, the script will do some validation.
    The target directory ($TargetDir) must exist
    The following components must be installed:
        - python (If a specific version is specified, then the script will verify that that version exists)
        - pip (Should be installed with any recent python)
        - virtualenv
        - git
If the validation fails, the script will exit with a report of failures
If the validation passes, then it will configure a python development environment in $TargetDir

    Create a virtual environment in $TargetDir\.env
    Install python testig modules
        - pylint
        - pytest
        - coverage
    Create a requirements.txt by freezing the virtualenv.
    Set up git precommit hooks
    Set up .gitignore
.EXAMPLE
Add-PythonScaffolding.ps1
.EXAMPLE
Add-PythonScaffolding.ps1 -TargetDir=C:\MyPythonProject -PythonVersion=C:\Python27\bin\python -PylintVersion=1.9.3
.PARAMETER TargetDir
The directory in which to initialize the python environment. If unspecified, the current directory is used. 
.PARAMETER PythonVersion
The version of python to use in the virtualenv. If unspecified, the system python is used.
.PARAMETER PylintVersion
The version of pylint to install. If unspecified, the latest version is installed.
.PARAMETER PytestVersion
The version of pytest to install. If unspecified, the latest version is installed.
.PARAMETER CoverageVersion
The version of coverage to install. If unspecified, the latest version is installed.
#>
param(
    [String] $TargetDir,
    [String] $PythonVersion,
    [String] $PylintVersion,
    [String] $PytestVersion,
    [String] $CoverageVersion
)

Function Add-PythonScaffolding{
    # Build up command strings (appending versions if specified)
    # We'll call these commands using Invoke-Expression

    # virtualenv installation command
    if ([string]::IsNullOrEmpty($PythonVersion)){
        $VirtualenvCommand = "virtualenv .env"
    }
    else {
        $VirtualenvCommand = "virtualenv -p $PythonVersion .env"  
    }

    # pylint installation command
    $PylintCommand = "pip install pylint"
    if (-not ([string]::IsNullOrEmpty($PylintVersion))){
        $PylintCommand = "pip install pylint=$PylintVersion"
    }
    # pytest installation command
    $PytestCommand = "pip install pytest"
    if (-not ([string]::IsNullOrEmpty($PytestVersion))) {
        $PytestCommand = "pip install pylint=$PytestVersion"
    }

    # coverage installation command
    $CoverageCommand = "pip install coverage"
    if (-not ([string]::IsNullOrEmpty($CoverageVersion))) {
        $CoverageCommand = "pip install pylint=$CoverageVersion"
    }

    # Call the commands and verify that they work
    Write-Host($VirtualenvCommand)
    Write-Host($PylintCommand)
    Write-Host($PytestCommand)
    Write-Host($CoverageCommand)

    # Create requirements.txt

    # Set up git precommit hooks

    # Set up .gitignore

    # Put VSCode integration in place
}

Function Validate-Prereqs{
    return $true
}

############################################################################
# Main script execution
############################################################################

# Project Directory
# Python version

if (Validate-Prereqs){
    Add-PythonScaffolding
}

