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

function GetLocationOfNewShortcut
{
    [string]$ext = ".lnk"
    if ($ExtIsDotUrl) {
        $ext = ".url"
    }
    return $CreationPath.Trim("\") + "\" + $ShortcutName.Trim(".url").Trim(".lnk") + $ext
}

$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($(GetLocationOfNewShortcut))
$Shortcut.TargetPath = $TargetPath # New shortcut will point to $TargetPath.
if ($TargetArgs) {
	# User specified that program at $TargetPath should be invoked with the 
    # arguments $TargetArgs.
	$Shortcut.Arguments = $TargetArgs
}
$Shortcut.Save()