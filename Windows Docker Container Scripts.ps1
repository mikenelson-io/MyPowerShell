start-process powershell -Verb runas

Enable-WindowsOptionalFeature -Online -FeatureName containers -All

#Win10 only support Hyper-V containers
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

$version = (Invoke-WebRequest -UseBasicParsing https://raw.githubusercontent.com/docker/docker/master/VERSION).Content.Trim()
Invoke-WebRequest "https://master.dockerproject.org/windows/amd64/docker-$($version).zip" -OutFile "$env:TEMP\docker.zip" -UseBasicParsing

Expand-Archive -Path "$env:TEMP\docker.zip" -DestinationPath $env:ProgramFiles

[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\Docker", [EnvironmentVariableTarget]::Machine) 

dockerd --register-service

Start-Service Docker

docker pull microsoft/nanoserver
docker run -it microsoft/nanoserver cmd
powershell.exe Add-Content C:\helloworld.ps1 'Write-Host "Hello World"'
exit
docker ps -a
docker commit <containerid> helloworld
docker images
docker run --rm helloworld powershell c:\helloworld.ps1

# Server install
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
Install-Package -Name docker -ProviderName DockerMsftProvider
docker run microsoft/dotnet-samples:dotnetapp-nanoserver

#IIS sample
docker run -it -p 80:80 microsoft/iis cmd
del C:\inetpub\wwwroot\iisstart.htm
echo "Hello World From a Windows Server Container" > C:\inetpub\wwwroot\index.html
exit
docker ps -a
docker commit pedantic_lichterman modified-iis

#Dockerfile example
powershell new-item c:\build\Dockerfile -Force
notepad c:\build\Dockerfile
	FROM microsoft/iis
	RUN echo "Hello World - Dockerfile" > c:\inetpub\wwwroot\index.html
docker build -t <user>/iis-dockerfile c:\Build
docker images
docker run -d -p 80:80 <user>/iis-dockerfile ping -t localhost
docker ps
docker rm -f <container name>

#Minecraft sample - https://hub.docker.com/r/itzg/minecraft-server/ 
docker run -d -it -e EULA=TRUE -p 25565:25565 --name mc itzg/minecraft-server
docker attach mc

#DockerCraft - Control containers in Minecraft - https://github.com/docker/dockercraft
# https://www.youtube.com/watch?v=eZDlJgJf55o



#### Older stuff #####

**********Add Containers to existing host*********
wget -uri https://aka.ms/tp5/Install-ContainerHost -OutFile C:\scripts\Install-ContainerHost.ps1
powershell.exe -NoProfile C:\Install-ContainerHost.ps1 -HyperV

**********Create a New Hyper-V Container Host*************
Get-VMSwitch | where {$_.SwitchType -eq “External”}
wget -uri https://aka.ms/tp5/New-ContainerHost -OutFile c:\scripts\New-ContainerHost.ps1
>>>> powershell.exe -NoProfile c:\New-ContainerHost.ps1 -VMName TP5CON -WindowsImage ServerDatacenterCore -Hyperv
>>>> powershell.exe -NoProfile c:\New-ContainerHost.ps1 -VMName TP5CON -WindowsImage NanoServer -Hyperv
Enter-PSSession -VMName TP5CON
Exit-PSSession

Install-PackageProvider ContainerProvider -Force
Find-ContainerImage
Install-ContainerImage -Name NanoServer
Get-ContainerImage

******* Install Docker on Windows - the HARD way *************
https://msdn.microsoft.com/en-us/virtualization/windowscontainers/deployment/docker_windows 

******* show difference between get-containerimage and docker images
docker service must be restarted to see images
Restart via service panel
sc docker stop
sc docker start


*******search hub
docker search *

New-Container -Name Demo -ContainerImageName NanoServer -SwitchName "Virtual Switch"
Get-Container
Start-Container -Name Demo
Install-WindowsFeature web-server
exit
Stop-Container -Name Demo
New-ContainerImage -ContainerName Demo -Name DemoIIS -Publisher Demo -Version 1.0
Get IP of container - Invoke-Command -ContainerName Demo {ipconfig} 



Create a Hyper-V container, use the New-Container command, specifying a Runtime of HyperV.
New-Container -Name HYPV -ContainerImageName NanoServer -SwitchName "External" -RuntimeType HyperV

***************AZURE*************
Select-azuresubscription
Get-Azuresubscription
get-azurepublishsettingsfile

Import-AzurePublishSettingsFile "c:\Nano\Azure.publishsettings"

start-service winrm
set-item wsman:\localhost\client\trustedhosts "nano.cloudapp.net" -Concatenate -force
get-item wsman:\localhost\client\trustedhosts

