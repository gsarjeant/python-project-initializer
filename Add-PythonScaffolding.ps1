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
Add-PythonScaffolding.ps1 -TargetDir C:\MyPythonProject -PythonVersion C:\Python27\python.exe -PylintVersion 1.9.3
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
.LINK
https://github.com/gsarjeant/python-project-initializer
#>
param(
    [String] $TargetDir=(Get-Location).toString(),
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
    Invoke-Expression($VirtualenvCommand)
    Invoke-Expression($PylintCommand)
    Invoke-Expression($PytestCommand)
    Invoke-Expression($CoverageCommand)

    # Create requirements.txt

    # Set up git precommit hooks

    # Set up .gitignore

    # Put VSCode integration in place
}

# There's a fair amount of logic here, so I'm splitting it out into its own function
Function Validate-Python{
    [Boolean] $PythonValid = $true

    Write-Host("Ensuring that python is installed")
    # Make sure that python is installed
    if($PythonVersion){
        # If a specific version of python was requested, look for that version
        $msg = "Specific python requested: $PythonVersion`n"
        $msg += "Verifying that $PythonVersion exists."
        Write-Host($msg)

        if(-not (Test-Path($PythonVersion))){
            $PythonValid = $false

            $msg = "ERROR: The specified version of python is not installed"
            $msg += "    $PythonVersion"
            Write-Error($msg)
        }
    } else {
        # If no specific version of python was requested, check the registry
        # to ensure that python was installed
        $msg = "Python version not specified. Using system python.`n"
        $msg += "Verifying that python is installed."

        # NOTE: HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* lists information
        #       for all installed apps that windows knows about
        # NOTE: Python 3 installs a bunch of things, so you'll get more than one response
        #       for python 3
        $UninstallKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        $InstalledPythonList = Get-ItemProperty($UninstallKey) | Where-Object { $_.Publisher -eq "Python Software Foundation"}
        if($InstalledPythonList.Length -eq 0){
            # No python versions were found
            $PythonValid = $false

            $msg = "ERROR: Python is not installed on this system. Please install python and try again."
            Write-Error($msg)
         }
    }

    return $PythonValid
}

Function Validate-Git{
    [Boolean] $GitValid = $true

    Write-Host("Ensuring that git is installed")
    # Make sure that git is installed

    # NOTE: HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* lists information
    #       for all installed apps that windows knows about
    $UninstallKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $InstalledGitList = Get-ItemProperty($UninstallKey) | Where-Object { $_.DisplayName -Match "^Git\ version"}
    if($InstalledGitList.Length -eq 0){
        # No python versions were found
        $GitValid = $false

        $msg = "ERROR: Git is not installed on this system. Please install git and try again."
        Write-Error($msg)
    }

    return $GitValid
}

Function Validate-Virtualenv{
    $VitualenvValid = $true
    $VirtualenvQuery = "pip --disable-pip-version-check show virtualenv"

    Write-Host("Ensuring that virtualenv is installed")

    $VirtualenvInfo = Invoke-Expression($VirtualenvQuery)

    if($VirtualenvInfo.Length -eq 0){
        $VirtualenvValid = $false

        $msg = "Virtualenv is not installed on this system. Please install virtualenv and try again."
        Write-Error($msg)
    }
    return $VirtualenvValid
}

Function Validate-Prereqs{
    #$PSCommandPath
    #Contains the full path and file name of the script that is being run. 
    #This variable is valid in all scripts.
    [Boolean] $PrereqsValid = $true

    [String] $CommandDir = Split-Path -Path $PSCommandPath

    # Ensure that $TargetDir isn't this project's directory
    Write-Host("Ensuring we aren't running against this script's parent directory")
    if($TargetDir -eq $CommandDir){
        $PrereqsValid = $false

        $msg = "ERROR: Script should not be run against its own directory.`n"
        $msg += "    Run it against a python project directory."
        Write-Error($msg)
    }

    # Validate that Python is installed
    if( -not(Validate-Python)) {
        $PrereqsValid -eq $false
    }

    # Validate that git is installed
    if( -not(Validate-Git)) {
        $PrereqsValid -eq $false
    }

    # Validate that virtualenv is installed
    if( -not(Validate-Virtualenv)) {
        $PrereqsValid -eq $false
    }

    return $PrereqsValid
}

############################################################################
# Main script execution
############################################################################

# Project Directory
# Python version

if([string]::IsNullOrEmpty($TargetDir)){
    Write-Host "No target dir"
    $TargetDir = (Get-Location).toString()
} else {
    Write-Host("Target dir: $TargetDir")
}


if (Validate-Prereqs){
    Write-Host("Nice prereqs")
    #Add-PythonScaffolding
} else {
    Write-Host("Bad prereqs")
}

