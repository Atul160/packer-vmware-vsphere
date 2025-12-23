<#
.SYNOPSIS
    This script will perform a basic choco package installation

.DESCRIPTION
    This script will perform a basic choco package installation

.NOTES
    This script assumes that chocolatey has already been installed and will fail if not installed

#>

[cmdletbinding()]

param(
    [Parameter(Mandatory)]
    [PSObject[]] $Application,

    [Parameter()]
    [String] $ChocoSource
)

forEach( $app in $application ){

    switch( $app ){

        { $_ -is [Hashtable] } {
            
            choco install $_.name --version $_.version --source $chocoSource
        }

        { $_ -is [String] } {

            choco install $_ --source $chocoSource
        }

        default { Write-Error "This option is not available" }
    }
}