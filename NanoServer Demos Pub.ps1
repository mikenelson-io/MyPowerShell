### A Collection of NanoServer demonstrations and tasks
### Compiled and tested on Server 2016 TP5
### By Mike Nelson - @mikenelsonio - nelmedia@gmail.com
###
### Requirements: You must have the Windows 2016 Server ISO file located somewhere where it can be mounted by the OS as a drive
###
### All of these are based on my demo config. You must change drive path, file names, etc. to match what you want to do.
### I am not responsible for anything that may or may not happen to you, your computer, your life, your dog's life, or anyone else's by using these demo's.

Mount-DiskImage -ImagePath "c:\iso\en_windows_server_2016_technical_preview_5_x64_dvd_8512312.iso"; Get-Volume
Copy-Item -Path D:\NanoServer\ -Destination C:\nano -Recurse

Import-Module -Global C:\nano\nanoserverimagegenerator\nanoserverimagegenerator.psm1 -verbose

Get-Help New-NanoServerImage
cls;Get-Command New-NanoServerImage -syntax
get-NanoServerPackage
Get-Help New-NanoServerImage -full
Get-Help New-NanoServerImage -Parameter * | Where-Object {$_.Required -eq $true}
Get-Command Edit-NanoServerImage -Syntax

### DEMO --> Build all images now --> talk about logs, bare metal --> Show MDT bare metal install option & talk about USB option as well
### Building 3 Images
### nanoems is to show EMS capability
### nanoIIS to show simple IIS build
### nano200 is main demo image with static IP
# Show missing parameter prompt with the EMS image build
New-NanoServerImage -deploymenttype guest -edition standard -mediapath d: -targetpath c:\nano\vhd\nanoems.vhd -computername nanoems -enableremotemanagementport -EnableEMS -EMSPort 1 -EMSBaudRate 9600
$NanoPass = (ConvertTo-SecureString -AsPlainText -Force -String "1P@ssw0rd")
New-NanoServerImage -deploymenttype guest -edition standard -mediapath d: -targetpath c:\nano\vhd\nanodemo200.vhd -computername nanodemo200 -enableremotemanagementport -CopyFiles C:\tools -Ipv4Address 10.10.1.200 -InterfaceNameorIndex Ethernet -Ipv4SubnetMask 255.255.255.0 -Ipv4Gateway 10.10.1.1 -Ipv4Dns 10.10.1.1,8.8.8.8 -AdministratorPassword $NanoPass
New-NanoServerImage -deploymenttype guest -edition standard -mediapath d: -targetpath c:\nano\vhd\nanoIIS.vhd -computername nanoIIS -enableremotemanagementport -Packages Microsoft-NanoServer-IIS-Package -CopyFiles C:\inetpub\index.htm -AdministratorPassword $NanoPass

### VMware Tools Driver Inject in case you want to run on VMware Workstation or ESXi
notepad C:\nano\demos\vmware_tools.ps1
c:\nano\vmtools_drivers

### DEMO --> SHOW VMM CONSOLE

# Must do to create VM's in VMM
Get-VMSwitch

### IIS Demo
New-VM -Name nanoIIS -VHDPath "c:\nano\VHD\nanoIIS.vhd" -switchname "External" -memorystartupbytes 512mb -generation 1
Start-VM nanoIIS -passthru
Get-VMNetworkAdapter -VMName nanoIIS
### DEMO --> Open local browser to NanoIIS IP & verify IIS working
Stop-VM nanoIIS
### Create HTTPS site on NanoIIS
## Copy the certificate to C:\Temp on the Nano server.
#Copy-Item "c:\nano\nanoIIS.pfx" \\nanoIIS\C$\Temp -Recurse
 ## Connect to the remote server
#$computer = "nanoIIS"
#$cred = Get-Credential (Credential "nanoIIS\Administrator")
# Enter-PSSession -ComputerName $computer -Credential $cred
## Import Cert
#certoc.exe -ImportPFX -p CertPasswordHere My c:\temp\nanoIIS.pfx
## Get the certificate thumbprint - Use your actual thumbprint instead of this example
#Get-ChildItem Cert:\LocalMachine\My | Select Subject,Thumbprint
## Change the thumbprint to the one you got above
#$certificate = Get-Item Cert:\LocalMachine\my\PasteYourThumbPrintHere
#$hash = $certificate.GetCertHash()
## Configure site
#Import-Module IISAdministration
#$sm = Get-IISServerManager
#$sm.Sites["Default Web Site"].Bindings.Add("*:443:", $hash, "My", "0")    # My is the certificate store name
#$sm.CommitChanges()
#Exit-PSSession
 # Copy the template site to the Nano server
#Copy-Item "c:\nano\IISsite\*" \\nanoIIS\c$\inetpub\wwwroot -Recurse 


### Create Main Demo Nano VM with static IP in VMM
New-VM -Name nano200 -VHDPath "c:\nano\VHD\nano200.vhd" -switchname "External" -memorystartupbytes 512mb -generation 1
# Could edit IP before 1st run - cannot be changed after 1st run
# Edit-NanoServerImage -target c:\nano\vhd\nano200.vhd -interfacenameorindex Ethernet -Ipv4Address 10.10.1.201 -Ipv4DNS 10.10.1.1 -Ipv4SubnetMask 255.255.255.0 -Ipv4Gateway 10.10.1.1
start-vm nano200 -passthru
# Verify IP
Get-VMNetworkAdapter -VMName nano200

### Create to show Boot time / Recovery Console / DHCP / EMS Console
New-VM -Name nanoems -VHDPath "c:\nano\VHD\nanoems.vhd" -switchname "External" -memorystartupbytes 512mb -generation 1

# Show posible script to mass create images & VM's
notepad c:\nano\demos\CreateNanoVMStart.ps1
### DEMO --> Talk about Show-Command in PoSH v5 - turn CLI into GUI
show-command -name new-nanoserverimage
show-command -name edit-nanoserverimage
show-command -name get-process
# Show attempt at PoSH GUI for builds
c:\nano\demos\New-NanoServer_GUI.ps1

### DEMO --> open VMM and connect to NanoEMS Console. Show boot time to login
Start-VM nanoEMS -passthru

### DEMO --> Go through Recovery Console options and settings

### DEMO --> Domain Join
# Switch to domain member and run scripts to build domain join image and harvest domain blob for offline join

### DEMO --> Switch to Azure and show VM build

### DEMO --> Show how to connect, run some demo tasks, show management, and make comparisions
# Set the stage
$NanoName = "nano200"
$NanoCred = Get-Credential

# Ways to connect & manage NanoServer
# PowerShell Remoting
# PowerShell Direct
# PowerShell DSC
# PowerShell WebAccess
# Remote GUI tools - server manager, Administrative Tools, RSMT (Azure), 3rd Party
# SCVMM
# CIM Sessions
# EMS

### Show Azure Remote Server Management (RMST) of Nano VM in Azure

### Show the new Remote Tab in ISE for establishing Remoting sessions

# Connect to nano200 via PowerShell Remoting
# Need to add trusted hosts. I use * for demo's, which is not secure, but hey, it's a demo.
#Set-Item WSMan:\localhost\Client\TrustedHosts "10.10.1.200"
Set-Item WSMan:\localhost\Client\TrustedHosts "*"   
Enter-PSSession -VMName $NanoName -Credential $NanoCred
# How can we do that connect via GUI?
Show-Command -Name Enter-PSSession

#Get process total number
Get-process;"`nNumber of processes = $((Get-process).count)"
# tp5core is around 76 processes

### Show psEdit - Tab in ISE
psEdit C:\tools\acsiitxt.ps1
# Change firewall
netsh advfirewall firewall set rule group="file and printer sharing" new enable=yes
# Run netstat
netstat -an
Exit-PSSession
# Disconnect-PSSession

# Connect via PowerShell Direct - must be one Hyper-V host to connect
Enter-PSSession -VMName $NanoName -credential $NanoCred
# Compare to TP4 which was 776
Get-Command -CommandType Cmdlet,Function | measure
# Change IP address
# $ife = (Get-NetAdapter -Name Ethernet).ifalias
# netsh interface ip set address $ife static 10.10.1.201
ipconfig
Exit-PSSession

# Send ScriptBlock to VM - cool way to run commands without entering sessions
Invoke-Command -VMName $NanoName { $PSVersionTable } -Credential $NanoCred
invoke-command -VMName $NanoName { ipconfig } -Credential $NanoCred
Invoke-Command -VMName $NanoName -FilePath c:\nano\demos\nano\colorservices.ps1 -Credential $NanoCred

# Connect to nano200 via WinRM
# Um, yeah, nobody really uses winrs, right?
# winrm quickconfig
# winrm s winrm/config/client '@{TrustedHosts="10.10.1.200"}'	
# chcp 65001
#	Test
# winrs -r:10.10.1.200 -u:Administrator -p:P@ssw0rd1! ipconfig /all

# Connect to nano200 via CIM over WinRM
$cim = New-CimSession -Credential $NanoCred -ComputerName $NanoName 
Get-CimInstance -CimSession $cim -ClassName Win32_ComputerSystem | Format-List *

# EMS Demo - nanoEMS image already built
# New-NanoServerImage -deploymenttype guest -edition standard -mediapath d: -targetpath c:\nano\vhd\nanoems.vhd -computername nanoems -enableremotemanagementport -EnableEMS -EMSPort 1 -EMSBaudRate 9600
# New-VM -Name nanoems -VHDPath "c:\nano\VHD\nanoems.vhd" -switchname "External" -memorystartupbytes 512mb -generation 1
# Simulate lost network connectivity
Remove-VMNetworkAdapter -VMName nanoEMS -VMNetworkAdapterName External
$VM = Get-VM -Computername W10-NUC1 -Name nanoEMS
$VM.ComPort1
$VM | Set-VMComPort -Path '\\.\pipe\nanoEMS' -Number 1 -Passthru
# Open Putty in Admin mode - add entry for nanoEMS with Serial connection to \\.\pipe\nanoEMS at 9600baud

# Create variable session for tasks		
$s = New-PSSession -ComputerName $NanoName -Credential $NanoCred

#copy files w/WMF5
copy-item -ToSession $s c:\tools\acsiitxt.ps1 -destination c:\ -recurse -verbose -force

Enter-PSSession $s

# Change Timezone 
function Get-TimeZone($Name)
{
 [system.timezoneinfo]::GetSystemTimeZones() | 
 Where-Object { $_.ID -like "*$Name*" -or $_.DisplayName -like "*$Name*" } | 
 Select-Object -ExpandProperty ID
} 
$timezone = Get-TimeZone Stockholm # Type in "your" capital and grab the time zone for that city.
tzutil.exe /s $timezone
# Reboot the server for the changes to take effect
Shutdown /r /t 10 # Set a time in seconds that suits you
#Exit-PSSession 

# Install Roles & Features after build
# Find-PackageProvider will want to install nuGet provider on first run. It's OK to do.
Find-PackageProvider
Get-PackageProvider
Install-PackageProvider NanoServerPackage -Force
Import-PackageProvider NanoServerPackage -Force
Find-NanoServerPackage

# Updating NanoServer - Not quite working well yet. Must disable Defender before updating or else it takes for....ever.
# WSUS/3rd party. 
$sess = New-CimInstance -Namespace root/Microsoft/Windows/WindowsUpdate -ClassName MSFT_WUOperationsSession
$scanResults = Invoke-CimMethod -InputObject $sess -MethodName ScanForUpdates -Arguments @{SearchCriteria="IsInstalled=0";OnlineScan=$true}
# If no updates - you will get this error back
# Invoke-CimMethod : A general error occurred that is not covered by a more specific error code.
# install all available updates - could take awhile
$sess = New-CimInstance -Namespace root/Microsoft/Windows/WindowsUpdate -ClassName MSFT_WUOperationsSession
$scanResults = Invoke-CimMethod -InputObject $sess -MethodName ApplyApplicableUpdates Restart-Computer
# verify installation
$sess = New-CimInstance -Namespace root/Microsoft/Windows/WindowsUpdate -ClassName MSFT_WUOperationsSession
$scanResults = Invoke-CimMethod -InputObject $sess -MethodName ScanForUpdates -Arguments @{SearchCriteria="IsInstalled=1";OnlineScan=$true}
# Show installed updates with verification
Get-WindowsPackage -Online

# Open-SSH Server install - Cool stuff!
install-packageprovider nuget -forcebootstrap -force
Register-packagesource -name chocolatey -provider nuget -location https://chocolatey.org/api/v2/ -trusted
install-package win32-openssh -provider nuget
cd "$((dir "env:ProgramFiles\nuget\packages\Win32-openssh*\tools" | select -last 1).fullname)"
cd 'C:\Program Files\nuget\packages\win32-openssh*\tools'
.".\barebonesinstaller.ps1" -SSHServerFeature
# Open Putty in Admin mode and connect via SSH!
# If you gotta do offline Open-SSH Server install
# https://github.com/DarwinJS/ChocoPackages/tree/master/win32-openssh

#Disconnect-PSSession
cd /

### Systernals install
# Variables
$Uri = 'https://download.sysinternals.com/files/SysinternalsSuite-Nano.zip'
$SysinternalsSuiteNanoZip = Join-Path -Path $env:temp -ChildPath SysinternalsSuite-Nano.zip
$SysinternalsSuiteNanoTempDir = Join-Path -Path $env:temp -ChildPath 'SysinternalsSuite-Nano'
$TargetDirectory = 'C:\Sysinternals'
# Download Zip-archive
Invoke-WebRequest -Uri $Uri -OutFile $SysinternalsSuiteNanoZip
# Create PowerShell Remoting session, expand Zip-archive and copy to Nano Server via the remoting session
$session = New-PSSession -ComputerName $NanoName -Credential $NanoCred
Invoke-Command -Session $session -ScriptBlock {mkdir $using:TargetDirectory}
Expand-Archive -Path $SysinternalsSuiteNanoZip -DestinationPath $SysinternalsSuiteNanoTempDir
Get-ChildItem -Path $SysinternalsSuiteNanoTempDir | Copy-Item -ToSession $session -Destination $TargetDirectory
# Clean up temp files
Remove-Item -Path $SysinternalsSuiteNanoZip
Remove-Item -Path $SysinternalsSuiteNanoTempDir -Recurse
# Test the tools in an interactive session
Enter-PSSession -Session $session
cd \
cls
cd 'C:\Sysinternals'
dir
.\logonsessions64.exe -accepteula
.\PsLoggedon64.exe -accepteula

Exit-PSSession

### MySQL install - still cannot get the service to start right. Bummer.
$MySQLUri = http://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.15-winx64.zip
$MySQLOutFileZip = Join-Path -Path $env:temp -ChildPath MySQL-Nano.zip
$MySQLNanoTempDir = Join-Path -Path $env:temp -ChildPath 'MySQL-Nano'
$TargetDirectory = c:\MySQL
Invoke-WebRequest -Uri $Uri -OutFile $MySQLOutFileZip
Expand-Archive -Path $MySQLOutFileZip -DestinationPath $MySQLNanoTempDir
Get-ChildItem -Path $MySQLNanoTempDir | Copy-Item -ToSession $session -Destination $TargetDirectory
Remove-Item -Path $MySQLOutFileZip
Remove-Item -Path $MySQLNanoTempDir -Recurse
$s2 = New-PSSession -computername $NanoName -Credential $NanoCred -Name "copyMySQL"
Enter-PSSession $s2
$env:path +=";C:\MySQL\bin"
New-Item -ItemType directory -Path C:\MySQL\data
Set-Content -value "ALTER USER 'root'@'localhost' IDENTIFIED BY 'password';" -Path c:\mysql\mysql-init.txt -Encoding Ascii
mysqld -init-file=c:\mysql\mysql-init.txt -console
mysqld.exe -install
get-service mysql
start-service mysql
get-service mysql
mysql -user=root -password=password -Bse "SHOW DATABASES;" > mytest.txt
type .\mytest.txt

Exit-PSSession


### DEMO --> DONE!