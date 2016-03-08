<#
    .SYNOPSIS
    Create a Powershell shortcut at the specified location.

    .DESCRIPTION
    Create a PowerShell shortcut at the specified location.
    If a command has been specified, then it shall be executed before the user gets
    control of the window.
    The window shall not be closed at the termination of this program.

    .PARAMETER CreationPath
    [Required, String]
    Absolute path of the location where the new PowerShell shortcut will be created.
    Throw a System.IO.IOException if the path is invalid.

    .PARAMETER Name
    [Required, String]
    Name of the new PowerShell shortcut.

    .PARAMETER 
    .PARAMETER Command
    [Optional, String]
    PowerShell command to execute after opening a new PowerShell window but before
    turning control over to the user.
    Be sure to use ('') instead of ("") within the command, if necessary.

    .EXAMPLE
    MakeBuildWindow.ps1 -CreationPath "C:\Users\UserId\Desktop" -Name "Test"
    --> Create a PowerShell shortcut called Test.lnk at C:\Users\UserId\Desktop.

    MakeBuildWindow.ps1 -CreationPath "C:\Users\UserId\Desktop" -Name "Test" -Command "cd 'C:\Users\UserId'"
    --> Create a PowerShell shortcut called Test.lnk at C:\Users\UserId\Desktop. 
        When the user clicks on the shorcut, Windows will open a PowerShell window 
        and execute "cd C:\Users\UserId" before turning control over to the user.
#>
[CmdletBinding(DefaultParameterSetName = 'Default')]
Param(
    [Parameter(Mandatory = $True)]
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

    [Parameter(Mandatory = $True)]
    $Name,

    [string]
    $Command
)

# Construct the PowerShell startup command based on user inputs.
if ($Command) {
    $Command = "-noexit -command `"" + $Command + "`""
}

# Create a shortcut at $CreationPath. The shortcut will refer to 
# $TargetPath (location of powershell.exe).
.\CreateShortcut.ps1 -CreationPath $CreationPath -ShortcutName $Name -TargetPath $($PsHome + "\powershell.exe") -TargetArgs $Command