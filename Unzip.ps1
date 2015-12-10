<#
    .DESCRIPTION
    Unzip the given zip file, and copy the contents to the specified destination.

    .PARAMETER Source
    [Required, String]
    Current location of the target zip file. Shall be an absolute path.

    .PARAMETER Destination
    [Required, String]
    Location that zip file's contents will be copied to. Shall be an absolute path.

    .PARAMETER DeleteZip
    [Optional, Switch]
    After unzipping to the destination:
        If enabled, then delete the zip file from the source path. 
        Otherwise, leave it alone.
#>
Param(
    [Parameter(Mandatory=$True)]
    [string]$Source,

    [Parameter(Mandatory=$True)]
    [string]$Destination,

    [switch]$DeleteZip
)

function ValidateInputs
{
    [array]$errorMessageList = @()
    if (!(Test-Path $Source)) {
        $errorMessageList += $Source
    }
    if (!(Test-Path $Destination)) {
        $errorMessageList += $Destination
    }

    if ($errorMessageList.Length -gt 0) {
        [string]$errorMessage = "Cannot find file(s) " + [string]::Join(" and ", $errorMessageList)
        throw [System.IO.FileNotFoundException] $errorMessage
    }
}

function Unzip
{
    [object]$WShell = New-Object -ComObject Shell.Application
    [object]$ZippedFolder = $WShell.NameSpace($Source)

    # Copy each item within the zipped folder (source namespace) into the
    # destination folder/namespace.
    $ZippedFolder.Items() | % { 
        $WShell.NameSpace($Destination).CopyHere($_)
    }

    # Clean-up files created by CopyHere.
    Push-Location
    cd $($Source.Substring(0, $Source.LastIndexOf('\')))
    del 0
    Pop-Location
}

ValidateInputs
Unzip
if ($DeleteZip) {
    del $Source
}