<#
    .SYNOPSIS
    Creates a program shortcut at the specified location.

    .DESCRIPTION
    Given a CreationPath and a TargetPath, the Create-Shortcut function shall
    create a shortcut pointing to TargetPath at CreationPath. In addition to
    the CreationPath and TargetPath, it should also be able to handle TargetArgs,
    which will be passed to the program at TargetPath as command-line parameters.

    .PARAMETER CreationPath
    [Required, String]
    Specifies the location at which the new shortcut should be created.
    If the CreationPath does not exist, then throw a System.IO.IOException.

    .PARAMETER ShortcutName
    [Required, String]
    Name of the new shortcut.

    .PARAMETER ExtIsDotUrl
    [Optional, Switch]
    If enabled, then append ".url" to ShortcutName. Otherwise, append ".lnk" 
    to ShortcutName.

    .PARAMETER TargetPath
    [Required, String] 
    Specifies location/program that this new shortcut will point to.

    .PARAMETER TargetArgs
    [Optional, String] 
    Specifies arguments to program that the new shortcut will point to.

    .EXAMPLE
    CreateShortcut.ps1 -CreationPath "C:\Users\abcd\Desktop"
                        -ShortcutName "Target"
                        -TargetPath "C:\Users\abcd\Documents\Test.docx"
    --> Creates a shortcut called Target.lnk on user abcd's desktop; Target.lnk 
        shall point to a document called Test.docx, so clicking on Target should open 
        up this document.

    CreateShortcut.ps1 -CreationPath "C:\Users\abcd\Desktop"
                        -ShortcutName "Target"
                        -ExtIsDotUrl 
                        -TargetPath "$PsHome\powershell.exe"
                        -TargetArgs '-noexit -command "echo Hello World"'
    --> Creates a shortcut called Target.url on user abcd's desktop; when the user 
        clicks on Target.lnk, it shall open up a PowerShell window, execute the command 
        "echo Hello World" (which will print Hello World) to the console, and leave the 
        window open.
#>
[CmdletBinding(DefaultParameterSetName = 'Default')]
Param(
    [Parameter(Mandatory=$True)]
    [string]
    [ValidateScript({
        if (!(Test-Path $_)) { 
            throw [System.IO.IOException] "`"$_`" is an invalid location." 
        }
        else {
            return $True
        }
    })]
    $CreationPath,

    [Parameter(Mandatory=$True)]
    [string]
    $ShortcutName,
    
    [switch]
    $ExtIsDotUrl,

    [Parameter(Mandatory=$True)]
    [ValidateScript({
        if (!(Test-Path $_)) { 
            throw [System.IO.IOException] "`"$_`" is an invalid location." 
        }
        else {
            return $True
        }
    })]
    [string]
    $TargetPath,

    [string]
    $TargetArgs
)

[string]$Ext = ".lnk"
if ($ExtIsDotUrl) {
    $Ext = ".url"
}

<#
    .SYNOPSIS
    Return the absolute path of the location where the shortcut will be created.

    .DESCRIPTION
    Account for the following:
    1. User may have added a "\" at the end of CreationPath.
    2. User may have added ".url" or ".lnk" extension to ShortcutName.
    Then, concatenate the reformatted CreationPath, ShortcutName, and Ext.
#>
function GetLocationOfNewShortcut
{
    # If the name already ends in ".lnk" or ".url" (shortcut extensions),
    # then remove the extension since we're going to be appending it anyway.
    [int]$lastDotIndex = $ShortcutName.LastIndexOf(".")
    if ($lastDotIndex -ne -1) {
        [string]$currentExt = $ShortcutName.Substring($lastDotIndex)
        if (($currentExt -eq ".lnk") -or ($currentExt -eq ".url")) {
            $ShortcutName = $ShortcutName.Substring(0, $lastDotIndex)            
        }
    }

    # Remove trailing "\" from CreationPath.
    $CreationPath = $CreationPath.Trim("\");

    return $CreationPath + "\" + $ShortcutName + $Ext
}

# Create the shortcut according to the specified config params.
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($(GetLocationOfNewShortcut))
$Shortcut.TargetPath = $TargetPath # New shortcut will point to $TargetPath.
if ($TargetArgs) {
    # User specified that program at $TargetPath should be invoked with the 
    # arguments $TargetArgs.
    $Shortcut.Arguments = $TargetArgs
}
$Shortcut.Save()