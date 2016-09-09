# Run this script only if we're using an elevated PowerShell environment.
$wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$prp=new-object System.Security.Principal.WindowsPrincipal($wid)
$adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
$IsAdmin=$prp.IsInRole($adm)
if (!$IsAdmin)
{
    throw '[Insufficient Permissions] Please run this' + 
		' script in an elevated PowerShell environment.'
}