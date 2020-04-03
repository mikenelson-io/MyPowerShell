$profilePath = 'https://raw.githubusercontent.com/mikenelson-io/MyPowerShell/master/profile.ps1'
 
$downloadString = '{0}?{1}' -f $profilePath, (New-Guid)
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($profilePath))
