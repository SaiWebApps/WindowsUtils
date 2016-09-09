<#
	.SYNOPSIS
	Install Microsoft Visual C++ Redistributables 2005, 2008, 2010, 2012,
	and 2013 onto this system.
	
	.DESCRIPTION
	Install Microsoft Visual C++ Redistributables 2005, 2008, 2010, 2012,
	and 2013 onto this system.
	If a certain version has already been installed, this script will not
	install it again.
	
	.EXAMPLE
	Install-VCRedist
#>

& "$PSScriptRoot\Require-ElevatedPS"

# Download Config
[string]$Url = 'http://188.138.70.225/Getintopc.com/' +
	'VC++_All_Redist_Packages.zip?md5=' +
	'zuoVmyV9MXAPQcDYg8KITw&expires=1473678083'
[string]$DownloadZipTo = $($env:UserProfile + 
	'\Downloads\VC++_Redist_Packages.zip')
[string]$UnzipTo = $($env:UserProfile + '\Downloads')
[string]$AllPackagesFolder = $UnzipTo + '\Fix'

# If the "Downloads" folder already contains files with the names,
# "VC++_Redist_Packages.zip" and/or "Fix", then delete them to avoid conflicts.
if (Test-Path $DownloadZipTo) {
	Remove-Item -Recurse -Force $DownloadZipTo
}
if (Test-Path $AllPackagesFolder) {
	Remove-Item -Recurse -Force $AllPackagesFolder
}

# Download Getintopc.com's zip file containing pertinent VC++ 
# Redistributable installers to the local "Downloads" folder.
Start-BitsTransfer -Source $Url -Destination $DownloadZipTo

# Unzip downloaded zip file to a directory called "Fix" within "Downloads."
# Delete the downloaded zip file afterwards.
& "$PSScriptRoot\Unzip.ps1" -Source $DownloadZipTo -Destination $UnzipTo -DeleteZip

# Determine the versions that have already been installed on the system.

# Delete installers corresponding to VC++ versions that have already been
# installed on this system.
. "$PSScriptRoot\Get-InstalledVCRedistVersions.ps1"
$InstalledVersions = Get-InstalledVCRedistVersions | % {
	[string]$version = $_.Split(' ')[3]
	[string]$arch = @{$True='x64';$False='x86'}[$_.Contains('x64')]
	[string]$exePath = $AllPackagesFolder + '\' + $version + 
		'\vcredist_' + $arch + '.exe'
	if (Test-Path $exePath) {
		Remove-Item -Recurse -Force $exePath
	}
}

# First, isolate all directories in $AllPackagesFolder.
# Then, isolate all directories with at least 1 installer.
# Then, execute each installer in each directory.
try {
	dir $AllPackagesFolder | ? { $_.mode[0] -eq 'd' } | ? { 
		$(dir $($AllPackagesFolder + '\' + $_.Name) | measure).Count -gt 0
	} | % {
		[string]$currentVersionDir = $($AllPackagesFolder + '\' + $_.Name)
		
		Push-Location
		cd $currentVersionDir

		# Execute installers. Pass appropriate flags based on VC++ version.
	    switch ($_.Name) 
		{
			2005 { dir | % { & ".\$_" /q | Out-Null }; break }
			2008 { dir | % { & ".\$_" /qb | Out-Null }; break }
			{($_ -eq 2010) -or ($_ -eq 2012)} {
				dir | % { & ".\$_" /passive /norestart | Out-Null };
				break
			}
			2013 { 
				dir | % { & ".\$_" /install /passive /norestart | Out-Null };
				break
			}
			default { echo 'Unsupported VC++ Redistributable Version' }
		}

		Pop-Location
	}
} finally {
	# Delete all resources that this script downloaded.
	& "$PSScriptRoot\Clear-DownloadsFolder.ps1"
}