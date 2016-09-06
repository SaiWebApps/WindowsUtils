# Run this script only if we're using an elevated PowerShell environment.
$wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$prp=new-object System.Security.Principal.WindowsPrincipal($wid)
$adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
$IsAdmin=$prp.IsInRole($adm)
if (!$IsAdmin)
{
    throw '[Insufficient Permissions] Please run this script in an elevated PowerShell environment.'
}

# Download Getintopc.com's zip file containing pertinent VC++ Redistributable installers
# to the local "Downloads" folder.
[string]$Url = 'http://188.138.70.225/Getintopc.com/VC++_All_Redist_Packages.zip?md5=zuoVmyV9MXAPQcDYg8KITw&expires=1473678083'
[string]$DownloadZipTo = $($env:UserProfile + '\Downloads\VC++_Redist_Packages.zip')
Start-BitsTransfer -Source $Url -Destination $DownloadZipTo

# Unzip the downloaded zip file into the "Downloads" folder, and delete said zip file.
[string]$UnzipTo = $($env:UserProfile + '\Downloads')
& "$PSScriptRoot\Unzip.ps1" -Source $DownloadZipTo -Destination $UnzipTo -DeleteZip

# Run installers.
[string]$AllPackagesFolder = $UnzipTo + '\Fix'

# Determine the versions that have already been installed on the system,
# and delete the appropriate installers.
[string[]]$InstalledVersions = 
    Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | ? { 
        $_.DisplayName -and $_.DisplayName.StartsWith('Microsoft Visual C++') 
    } | % { $_.DisplayName }

$InstalledVersions | ? { $_.Contains('x86') } | % { 
    [string]$version = $_.Split(' ')[3]
    [string]$installerPath = $($AllPackagesFolder + '\' + $version + '\vcredist_x86.exe')
    if (Test-Path $installerPath) {
        Remove-Item $installerPath
    }
}
$InstalledVersions | ? { $_.Contains('x64') } | % { 
    [string]$version = $_.Split(' ')[3]
    [string]$installerPath = $($AllPackagesFolder + '\' + $version + '\vcredist_x64.exe')
    if (Test-Path $installerPath) {
        Remove-Item $installerPath
    }
}

# First, isolate all directories in $AllPackagesFolder.
# Then, isolate all directories with at least 1 installer.
# Then, execute each installer in each directory.
dir $AllPackagesFolder | ? { $_.mode[0] -eq 'd' } | ? { 
    $(dir $($AllPackagesFolder + '\' + $_.Name) | measure).Count -gt 0
} | % {
    [string]$currentVersionDir = $($AllPackagesFolder + '\' + $_.Name)
    Push-Location
    cd $currentVersionDir

    # Execute installer. Pass appropriate flags based on VC++ version.
    switch ($_.Name) 
    {
        2005 {
            dir | % {
                & ".\$_" /q | Out-Null
            };
            break
        }

        2008 {
            dir | % {
                & ".\$_" /qb | Out-Null
            };
            break
        }
        
        2010 {}
        2012 {
            dir | % {
                & ".\$_" /passive /norestart | Out-Null
            };
            break
        }
        
        2013 {
            dir | % {
                & ".\$_" /install /passive /norestart | Out-Null
            };
            break
        }

        default { 'Unsupported VC++ Redistributable Version' }
    }

    Pop-Location
}

# Delete installers now that we've installed the redist packages.
& "$PSScriptRoot\Clear-DownloadsFolder.ps1"