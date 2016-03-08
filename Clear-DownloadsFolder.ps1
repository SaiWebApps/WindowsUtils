<#
    .DESCRIPTION
    Empty the downloads folder, and print the number of files deleted.

    .PARAMETER DownloadsFolderPath
    [Optional, String]
    Absolute path of the Downloads folder.
    Default value is $env:UserProfile + "\Downloads\*".
#>
Param(
    [string]$DownloadsFolderPath = $($env:UserProfile + "\Downloads\*")
)

Remove-Item -Path $DownloadsFolderPath -Recurse -Force