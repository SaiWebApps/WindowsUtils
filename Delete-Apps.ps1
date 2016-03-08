<#
    .SYNOPSIS
    Uninstall the user-specified Modern (Windows 8+) apps.

    .DESCRIPTION
    Given either a semicolon delimited list or an XML configuration file
    containing the names of target Modern apps, uninstall the specified apps
    from the system.
    If an app cannot be found, then the script simply moves on to the next app
    in the list.
    If multiple results were found for a given app, then the script will query
    the user to select 1 of the results and subsequently delete the selected result.

    .PARAMETER List
    (Optional) A semicolon-delimited list of apps to uninstall.

    .PARAMETER XMLPath
    (Optional) The path to a XML config file organized as follows:
    <AppsToDelete>
        <App> AppName1 </App>
        <App> AppName2 </App>
        ....
    </AppsToDelete>

    EXAMPLE:
    <AppsToDelete>
        <App> Xbox </App>
        <App> Reading List </App>
        <App> Getting Started </App>
        <App> Scan </App>
        <App> Music </App>
        <App> Solitaire </App>
        <App> Microsoft Family </App>
        <App> Sports </App>
        <App> Finance </App>
        <App> Weather </App>
    </AppsToDelete>

    .EXAMPLE
    DeleteApps.ps1
    -> Display a list of all Modern apps installed on the system, allow the
    user to select 1 or more of them to delete, and delete the specified apps.

    DeleteApps.ps1 -List "Music;Video;Xbox"
    -> Delete the Music, Video, and Xbox apps, if they exist.

    DeleteApps.ps1 -XMLPath "C:\DeleteAppsConfig.xml"
    -> Delete the apps specified within DeleteAppsConfig.xml, if they exist.
#>
Param(
    [string]$List,
    [string]$XMLPath
)

# Imports
. "$PSScriptRoot/Process-UserSelection.ps1"

<#
    .SYNOPSIS
    Return the list of Modern apps that the user wants to delete.

    .DESCRIPTION
    If the user specified a semicolon-delimited string of app names, then split
    the string on ";" to get a list of target apps.
    If the user specified a XML Config file path via the "-XMLPath" flag, then
    read the XML file, and extract the specified app names into a list.
    If the user specified both, then we will do both of the above.
    At the end, return the list of apps that the user wants to delete.

    .EXAMPLE
    GetListOfTargetApps
#>
function GetListOfTargetApps
{
    [array]$ListOfAppsToDelete = @()
    if ($XMLPath) {
        [xml]$XmlFile = Get-Content $XMLPath
        $ListOfAppsToDelete += $XmlFile.SelectNodes("//AppsToDelete/App") | % { $_.InnerXML }
    }
    if ($List) {
        [array]$Tokens = $List.Split(";")
        $ListOfAppsToDelete += $Tokens
    }

    return $ListOfAppsToDelete
}

<#
    .SYNOPSIS
    Delete the modern app with the specified name.

    .DESCRIPTION
    Delete the modern app with the specified name. If successful, then print
    "Successfully deleted " + app's full package name. Otherwise, print out
    an error message to indicate failure.

    .PARAMETER AppName
    Name of the Modern app that needs to be deleted
#>
function DeleteApp
{
    Param(
        [string]$AppName
    )

    $AppName = $AppName.Replace(" ", "").ToLower()
    [array]$Results = get-appxpackage | ? { $_.Name.ToLower().Contains($AppName) }
    [int]$NumResults = $Results.Length
    if ($NumResults -eq 0) {
        Write-Host $("Unable to delete " + $AppName)
        return
    }

    [string]$PackageFullName = $Results[0].PackageFullName
    if ($NumResults -gt 1) {
        ProcessUserSelection -AvailableChoices $Results -Title "Deleting $AppName" -Prompt "Specify which apps should be deleted"
        $PackageFullName = GetUserSelection -Results $Results
    }
    remove-appxpackage -Package $PackageFullName -ErrorAction "SilentlyContinue"
    if ($?) {
        Write-Host $("Successfully deleted " + $PackageFullName) -ForegroundColor "Green"
    }
    else {
        Write-Host $("Failed to delete " + $PackageFullName) -ForegroundColor "Red"
    }
}

# If the user either directly specified a semicolon-separated list of targets or
# the path to a XML file with targets, then delete those target Modern apps
# and move on with life.
[array]$targetApps = $(GetListOfTargetApps)
# But if the user did not specify any targets, then show the list of all Modern
# apps on the system, and ask the user to select 1+ of them to delete.
if (-Not $List -and -Not $XMLPath) {
    [array]$modernAppNames = get-appxpackage | % { $_.Name }
    [string]$title = "List of Currently Installed Modern/Universal Apps"
    [string]$prompt = "Delete apps (specify numbers in comma-separated list)"
    $targetApps = ProcessUserSelection -AvailableChoices $modernAppNames -Title $title -Prompt $prompt
}

foreach ($app in $targetApps) {
    DeleteApp -AppName $app
}