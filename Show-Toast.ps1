Param(
	[Parameter(Mandatory=$True)][string]$Title,
	[Parameter(Mandatory=$True)][string]$Text,

	[int]$Duration,
	[string]$IconSrc,
	[switch]$SuccessIcon
)

# Default Toast duration = 10000 ms
if (-Not $Duration) {
	[int]$Duration = 10000
}
# If no icon is specified...
if (-Not $IconSrc) {
	[string]$IconSrc = "$PSScriptRoot\ico\failure.ico"
	if ($SuccessIcon) {
		$IconSrc = "$PSScriptRoot\ico\success.ico"
	}
}

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$Toast = New-Object System.Windows.Forms.NotifyIcon
$Toast.BalloonTipTitle = $Title
$Toast.BalloonTipText = $Text
$Toast.Icon = $IconSrc
$Toast.Visible = $True
$Toast.ShowBalloonTip($Duration)
$Toast.Dispose()