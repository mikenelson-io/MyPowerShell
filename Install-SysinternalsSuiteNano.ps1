#requires -Version 5

<#
 NAME: Install-SysinternalsSuiteNano.ps1
 AUTHOR: Jan Egil Ring (@JanEgilRing)
 COMMENT: This script will download the Nano Server version of the Sysinternals Suite and extract it to the specified target directory.
 Prerequisites:
        You will need administrative credentials for the Nano Server machine
 Usage: Customize the variables $NanoServer and $NanoCred in the top of the script, then run line by line.
 Notes: -Expand-Archive does not work on Nano Server in Windows Server 2016 Technical Preview 5, but is expected to work in RTM. Due to this issue, the zip-expansion must be performed locally.
        -Due to the use of file copy via PS Remoting, PowerShell 5.0 is required.
 You have a royalty-free right to use, modify, reproduce, and 
 distribute this script file in any way you find useful, provided that 
 you agree that the creator, owner above has no warranty, obligations, 
 or liability for such use. 
 VERSION HISTORY: 
 1.0 05.07.2016 - Initial release
#>

# Variables
$Uri = 'https://download.sysinternals.com/files/SysinternalsSuite-Nano.zip'
$SysinternalsSuiteNanoZip = Join-Path -Path $env:temp -ChildPath SysinternalsSuite-Nano.zip
$SysinternalsSuiteNanoTempDir = Join-Path -Path $env:temp -ChildPath 'SysinternalsSuite-Nano'
$NanoServer = '10.10.1.103'
$NanoCredential = Get-Credential
$TargetDirectory = 'C:\Sysinternals'

# Download Zip-archive
Invoke-WebRequest -Uri $Uri -OutFile $SysinternalsSuiteNanoZip

# Create PowerShell Remoting session, expand Zip-archive and copy to Nano Server via the remoting session
$session = New-PSSession -ComputerName $NanoServer -Credential $NanoCredential

Invoke-Command -Session $session -ScriptBlock {mkdir $using:TargetDirectory}

Expand-Archive -Path $SysinternalsSuiteNanoZip -DestinationPath $SysinternalsSuiteNanoTempDir
 
Get-ChildItem -Path $SysinternalsSuiteNanoTempDir | Copy-Item -ToSession $session -Destination $TargetDirectory

# Clean up temp files
Remove-Item -Path $SysinternalsSuiteNanoZip
Remove-Item -Path $SysinternalsSuiteNanoTempDir -Recurse

# Test the tools in an interactive session
Enter-PSSession -Session $session
cd\
cls

cd 'C:\Sysinternals'
dir

.\logonsessions64.exe -accepteula
.\PsLoggedon64.exe -accepteula

Exit-PSSession