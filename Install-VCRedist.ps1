Param(
    [string]$ExcludeVersions,
    [string]$Delimiter = ','
)

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
# Delete the installers for the versions specified in ExcludeVersions.
if ($ExcludeVersions) {
    $ExcludeVersions.Split(',') | % {
        Remove-Item -Recurse -Force $($AllPackagesFolder + '\' + $_)
    }
}

dir $AllPackagesFolder | ? { $_.mode[0] -eq 'd' } | % {
    Push-Location

    cd $($AllPackagesFolder + '\' + $_.name)
    switch ($_.name) 
    {
        2005 {
            .\vcredist_x86.exe /q | Out-Null;
            .\vcredist_x64.exe /q | Out-Null;
            break
        } 
        
        2008 {
            .\vcredist_x86.exe /qb | Out-Null;
            .\vcredist_x64.exe /qb | Out-Null;
            break
        }
        
        2010 {
            .\vcredist_x86.exe /passive /norestart | Out-Null;
            .\vcredist_x64.exe /passive /norestart | Out-Null;
            break
        }
        
        2012 {
            .\vcredist_x86.exe /passive /norestart | Out-Null;
            .\vcredist_x64.exe /passive /norestart | Out-Null;
            break
        }
        
        2013 {
            .\vcredist_x86.exe /install /passive /norestart | Out-Null;
            .\vcredist_x64.exe /install /passive /norestart | Out-Null;
            break
        }

        default { 'Unsupported VC++ Redistributable Version' }
    }

    Pop-Location
}

# Delete installers now that we've installed the redist packages.
& "$PSScriptRoot\Clear-DownloadsFolder.ps1"