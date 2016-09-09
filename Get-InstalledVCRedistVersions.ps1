<#
	.SYNOPSIS
	Extract information about the versions of Microsoft Visual C++ 
	Redistributable on this system from a given registry path.
	
	.DESCRIPTION
	Return a string[] with the names of the Microsoft Visual C++
	Redistributables listed at the specified registry path.

	.PARAMETER RegPath
	[Required][String]
	Registry path that presumably contains information about
	installed VC++ redistributables.
	
	.EXAMPLE
	Get-InstalledVCRedistVersionsFromRegPath 
		-RegPath "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
#>
function Get-InstalledVCRedistVersionsFromRegPath
{
	Param(
		[Parameter(Mandatory=$True)]
		[string]$RegPath
	)

	return Get-ItemProperty $RegPath | ? {
		$_ -and $_.DisplayName -and 
		$_.DisplayName.StartsWith('Microsoft Visual C++') -and
		$_.DisplayName.Contains('Redistributable')
	} | % { $_.DisplayName }
}

<#
	.SYNOPSIS
	Identify all the different versions of Microsoft Visual C++
	Redistributables installed on this system.
	
	.DESCRIPTION
	Return a string[] with the names of the various Microsoft Visual C++
	Redistributables installed on this system.
	
	.EXAMPLE
	# Get the actual version numbers (years) of the Microsoft Visual C++
	# Redistributables on this system.
	[string[]]$InstalledVersions = Get-InstalledVCRedistVersions
	$InstalledVersions | % {
		$_.Split(' ')[3]
	}
#>
function Get-InstalledVCRedistVersions
{
	[string[]]$InstalledVersions = @()

	[string[]]$RegPaths = @(
		'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
		'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
	)	
	$RegPaths | % {
		$InstalledVersions += 
			Get-InstalledVCRedistVersionsFromRegPath -RegPath $_
	}
	
	return $InstalledVersions
}