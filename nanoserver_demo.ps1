
# Start DEMO

Set-ExecutionPolicy Unrestricted

Mount-DiskImage -ImagePath "c:\iso\en_windows_server_2016_technical_preview_5_x64_dvd_8512312.iso"; Get-Volume

#Copy-Item -Path D:\NanoServer\ -Destination C:\nano -Recurse

Import-Module -Global C:\nano\nanoserverimagegenerator\nanoserverimagegenerator.psm1 -verbose

Get-Help New-NanoServerImage

cls;Get-Command New-NanoServerImage -syntax

get-NanoServerPackage

Get-Help New-NanoServerImage -full

Get-Help New-NanoServerImage -Parameter * | Where-Object {$_.Required -eq $true}

Get-Command Edit-NanoServerImage -Syntax

New-NanoServerImage -deploymenttype guest -edition standard -mediapath d: -targetpath c:\nano\vhd\nanodemo1.vhd -computername nanodemo1 -enableremotemanagementport

$NanoPass = (ConvertTo-SecureString -AsPlainText -Force -String "P@ssw0rd1!")

New-NanoServerImage -deploymenttype guest -edition standard -mediapath d: -targetpath c:\nano\vhd\nanodemo200.vhd -computername nanodemo200 -enableremotemanagementport -CopyFiles C:\tools -Ipv4Address 10.10.1.200 -InterfaceNameorIndex Ethernet -Ipv4SubnetMask 255.255.255.0 -Ipv4Gateway 10.10.1.1 -Ipv4Dns 10.10.1.1,8.8.8.8 -AdministratorPassword $NanoPass


New-NanoServerImage -deploymenttype guest -edition standard -mediapath d: -targetpath c:\nano\vhd\nanoIIS.vhd -computername nanoIIS -enableremotemanagementport -Packages Microsoft-NanoServer-IIS-Package -AdministratorPassword $NanoPass

### VMware Tools Driver Inject
code C:\nano\demos\nano\vmware_tools.ps1
c:\nano\vmtools_drivers

### VMM

Get-VMSwitch

New-VM -Name nanoIIS -VHDPath "c:\nano\VHD\nanoIIS.vhd" -switchname "External" -memorystartupbytes 512mb -generation 1

Start-VM nanoIIS -passthru

Get-VMNetworkAdapter -VMName nanoIIS

### Open IIS

Stop-VM nanoIIS

New-VM -Name nanodemo200 -VHDPath "c:\nano\VHD\nanodemo200.vhd" -switchname "External" -memorystartupbytes 512mb -generation 1

start-vm nanodemo200 -passthru

New-VM -Name nanodemo1 -VHDPath "c:\nano\VHD\nanodemo1.vhd" -switchname "External" -memorystartupbytes 512mb -generation 1

Get-VMNetworkAdapter -VMName nanodemo200

# Edit-NanoServerImage -target c:\nano\vhd\nanodemo200.vhd -interfacenameorindex Ethernet -Ipv4Address 10.10.1.201 -Ipv4DNS 10.10.1.1 -Ipv4SubnetMask 255.255.255.0 -Ipv4Gateway 10.10.1.1

### NANODEMO1 CONSOLE BOOT
Start-VM nanodemo1 -passthru

code c:\nano\scripts\CreateNanoVMStart.ps1

show-command -name new-nanoserverimage

show-command -name edit-nanoserverimage

show-command -name get-process

c:\nano\scripts\New-NanoServer_GUI.ps1

### Domain Join

### Azure build

$NanoName = "nanodemo200"
$NanoCred = Get-Credential

# Ways to connect & manage
# PowerShell Remoting
# PowerShell Direct
# PowerShell DSC
# PowerShell WebAccess
# Remote GUI tools - server manager, Administrative Tools, RSMT, 3rd Party
# SCVMM
# CIM Sessions
# EMS

### Azure Server Management

# Show Remote Tab in ISE

# Connect to nanodemo1 via PowerShell Remoting
Set-Item WSMan:\localhost\Client\TrustedHosts "10.10.1.200"
Set-Item WSMan:\localhost\Client\TrustedHosts "*"   
Enter-PSSession -VMName $NanoName -Credential $NanoCred

Show-Command -Name Enter-PSSession

#Get process total number
Get-process;"`nNumber of processes = $((Get-process).count)"
# Open tp5core and compare count

### Show edit
psEdit C:\tools\acsiitxt.ps1
netsh advfirewall firewall set rule group="file and printer sharing" new enable=yes
netstat -an
Exit-PSSession
# Disconnect-PSSession

# Connect via PowerShell Direct
Enter-PSSession -VMName $NanoName -credential $NanoCred
# Was 776 in TP4
Get-Command -CommandType Cmdlet,Function | measure
# Change IP address
# $ife = (Get-NetAdapter -Name Ethernet).ifalias
# netsh interface ip set address $ife static 10.10.1.201
ipconfig
Exit-PSSession

# Send ScriptBlock to VM
Invoke-Command -VMName $NanoName { $PSVersionTable } -Credential $NanoCred
invoke-command -VMName $NanoName { ipconfig } -Credential $NanoCred
Invoke-Command -VMName $NanoName -FilePath c:\nano\demos\nano\colorservices.ps1 -Credential $NanoCred

# Connect to nanodemo200 via WinRM
# winrm quickconfig
# winrm s winrm/config/client '@{TrustedHosts="10.10.1.200"}'	
# chcp 65001
#	Test
# winrs -r:10.10.1.200 -u:Administrator -p:P@ssw0rd1! ipconfig /all

# Connect to nanodemo200 via CIM over WinRM
$cim = New-CimSession -Credential $NanoCred -ComputerName $NanoName 
Get-CimInstance -CimSession $cim -ClassName Win32_ComputerSystem | Format-List *

# EMS Demo
# New-NanoServerImage -deploymenttype guest -edition standard -mediapath d: -targetpath c:\nano\vhd\nanoems.vhd -computername nanoems -enableremotemanagementport -EnableEMS -EMSPort 1 -EMSBaudRate 9600
# New-VM -Name nanoems -VHDPath "c:\nano\VHD\nanoems.vhd" -switchname "External" -memorystartupbytes 512mb -generation 1
# $VM = Get-VM -Computername W10-NUC1 -Name nanoems
# $VM.ComPort1
# $VM | Set-VMComPort -Path '\\.\pipe\NANOEMS' -Number 1 -Passthru
# Open Putty
		
$s = New-PSSession -ComputerName $NanoName -Credential $NanoCred

#copy files w/WMF5
copy-item -ToSession $s c:\tools\acsiitxt.ps1 -destination c:\ -recurse -verbose -force

Enter-PSSession $s

# install Roles & Features after build
Find-PackageProvider
Get-PackageProvider
Install-PackageProvider NanoServerPackage -Force
Import-PackageProvider NanoServerPackage -Force
Find-NanoServerPackage

# Updating NanoServer - Defender Issue
# WSUS/3rd party. 
$sess = New-CimInstance -Namespace root/Microsoft/Windows/WindowsUpdate -ClassName MSFT_WUOperationsSession
$scanResults = Invoke-CimMethod -InputObject $sess -MethodName ScanForUpdates -Arguments @{SearchCriteria="IsInstalled=0";OnlineScan=$true}

# If no updates
# Invoke-CimMethod : A general error occurred that is not covered by a more specific error code.

# install all available updates
$sess = New-CimInstance -Namespace root/Microsoft/Windows/WindowsUpdate -ClassName MSFT_WUOperationsSession
$scanResults = Invoke-CimMethod -InputObject $sess -MethodName ApplyApplicableUpdates Restart-Computer

# verify installation
$sess = New-CimInstance -Namespace root/Microsoft/Windows/WindowsUpdate -ClassName MSFT_WUOperationsSession
$scanResults = Invoke-CimMethod -InputObject $sess -MethodName ScanForUpdates -Arguments @{SearchCriteria="IsInstalled=1";OnlineScan=$true}

# Show installed updates with verification
Get-WindowsPackage -Online

# SSH Server install
install-packageprovider nuget -forcebootstrap -force
Register-packagesource -name chocolatey -provider nuget -location https://chocolatey.org/api/v2/ -trusted
install-package win32-openssh -provider nuget
cd "$((dir "env:ProgramFiles\nuget\packages\Win32-openssh*\tools" | select -last 1).fullname)"
cd 'C:\Program Files\nuget\packages\win32-openssh*\tools'
.".\barebonesinstaller.ps1" -SSHServerFeature
# Open Putty
# Offline SSH Server install
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

### MySQL install
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