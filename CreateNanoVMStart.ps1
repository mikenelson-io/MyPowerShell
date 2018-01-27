[CmdletBinding()]
Param(
   [Parameter(Mandatory=$True)]
   [string]$serverName
)

# Script must be running as Administrator
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    Break
}

# Paths & Variables
$nanoPath = "c:\nano"
$vhdMinBytes = 256MB
$vhdMaxBytes = 2GB

$isoPath = "d:"
$basePath = "$nanoPath\Base"
$targetPath = "$nanoPath\$serverName\beer3.vhd"
$adminPassword = ConvertTo-SecureString "Pass@word1" -AsPlainText -Force

# Main

# Check if NanoServerImageGenerator module is imported and import it
$webmod = Get-Module NanoServerImageGenerator
if($webmod -eq $null -or $webmod.Count -eq 0)
{
    Import-Module c:\nano\NanoServerImageGenerator -verbose
}

Write-Host -nonewline "Creating Nano Server Image "
Write-Host -nonewline -ForegroundColor $ColorScheme.Help_Header $serverName
Write-Host -nonewline " in folder "
Write-Host -ForegroundColor $ColorScheme.Help_Header $targetPath


    # Create the new Nano Server VHD
    New-NanoServerImage -Edition Standard -DeploymentType Guest -MediaPath $isoPath -TargetPath $targetPath -ComputerName $serverName -EnableRemoteManagementPort -AdministratorPassword $adminPassword -CopyFiles c:\tools -SetupCompleteCommands 'powershell "& ""C:\Tools\Setup.ps1"""'
    # Create a new VM and using the VHD created above.
    New-VM -Name $serverName -Generation 1 -MemoryStartupBytes $vhdMinBytes -VHDPath $targetPath -SwitchName "External"
    Set-VMMemory $serverName -DynamicMemoryEnabled $true -MinimumBytes $vhdMinBytes -StartupBytes $vhdMinBytes -MaximumBytes $vhdMaxBytes -Priority 50 -Buffer 20

    Write-Host -nonewline "Starting VM "
    Write-Host -nonewline -ForegroundColor $ColorScheme.Help_Header $serverName
    Write-Host -nonewline "..."
    
#    Start-VM $serverName
    Write-Host -ForegroundColor $ColorScheme.ConfirmText " Done."