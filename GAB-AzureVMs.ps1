########### Global Azure Bootcamp 2017 demo script
########### Managing Azure VM with PowerShell
########### Compiled by Mike Nelson - @nelmedia
###########
########### No warranty expressed or implied. Use at your own risk.
###########

## Install the modules
#Get latest PowerShellGet
Install-PackageProvider Nuget -Force
Install-Module -Name PowerShellGet -Force
Get-Module PowerShellGet -list | Select-Object Name,Version,Path
Install-Module Azure -AllowClobber

# Add the PSGallery Repo - Recommended but not required
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

#Import the Azure modules
Import-Module Azure
Get-Module -ListAvailable | Where-Object{ $_.Name -eq 'Azure' } | Select Version, Name, Author, PowerShellVersion  | Format-List
Get-Command -Module Azure*
Get-Command -Module AzureRM*
Show-Command Get-AzureRmVM
Show-Command Set-AzureRmContext

## Connections
# Legacy Azure Service Management (Classic) Connection
Add-AzureAccount

# ARM access
Add-AzureRmAccount

## Authentication storage
#Save login creds to json file - plaintext!!
Save-AzureRmProfile -Path 'c:\temp\1\entprofile.json'
#Select the profile - multiple accounts? You need to import each one.
Select-AzureRmProfile -Path 'c:\temp\1\AzureRmProfile-MPN.json'
# Add this to your ISE profile if you want to load the profile everytime
Select-AzureRmProfile -Path 'c:\temp\AzureRmProfile-MPN.json' | out-null
#Generate and download the Windows Azure PublishSettings File (ASM - Classic)
Get-AzurePublishSettingsFile
#Import Windows Azure PublishSettings File - Use for Classic SM requirements (ASM - Classic)
Import-AzurePublishSettingsFile Azure.publishsettings

#List Azure Regions serviced
Get-AzureLocation | sort DisplayName | Select DisplayName

# List ARM subscription(s)
Get-AzureRmSubscription

# Show the current ARM subscription
Get-AzureRmContext

# Change the current if necessary
Set-AzureRmContext -SubscriptionName 'Nelmedia MPN'

# Setup WSMAN for PowerShell Remoting - Do this on your PoSH host machine
get-item wsman:\localhost\Client\TrustedHosts
# If service is stopped
Start-Service WinRM
# Check it again
get-item wsman:\localhost\Client\TrustedHosts
# Add hosts or wildcard
#set-item wsman:\localhost\Client\TrustedHosts -value  "Local Machine Name/IP" -Concatenate
set-item wsman:\localhost\Client\TrustedHosts -value  "*"
# Check it one more time
get-item wsman:\localhost\Client\TrustedHosts

# Create Resource Group, if one does not exist
New-AzureRmResourceGroup -Name gabdemo100rg -Location 'Central US'

# Create a Key Vault
$vaultName = 'gabdemokv'
$certificateName = 'YourFirstCertificate'
New-AzureRmKeyVault -VaultName $vaultName -ResourceGroupName 'gabdemo100rg' -Location 'Central US'
# Create a self-signed Cert
$policy = New-AzureKeyVaultCertificatePolicy   -SubjectName "CN=www.mydomain.com"   -IssuerName Self   -ValidityInMonths 12
Add-AzureKeyVaultCertificate -VaultName $vaultName -Name $certificateName -CertificatePolicy $policy 
# Add a PFX or PEM cert if you have it
$securepfxpwd = ConvertTo-SecureString -String '123' -AsPlainText -Force
$cer = Import-AzureKeyVaultCertificate -VaultName $vaultName -Name $certificateName -FilePath 'c:\clientcert.pfx' -Password $securepfxpwd

## Create the base Network
# Create Network Subnet
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name gabSubnet -AddressPrefix 192.168.1.0/24
# Virtual Network
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName gabdemo100rg -Location 'Central US' -Name gabvNET -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig
# Public IP & DNS - Must be changed for every VM created
$pip = New-AzureRmPublicIpAddress -ResourceGroupName gabdemo100rg -Location 'Central US' -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name "gabpublicdns$(Get-Random)"
# Create Net Security if needed
# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name gabNetworkSecurityGroupRuleRDP -Description "Allow RDP" -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow
$nsgRuleWinRM = New-AzureRmNetworkSecurityRuleConfig -Name gabNetworkSecurityGroupRuleWinRM  -Description "Allow WinRM" -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 5986 -Access Allow
# For Linux VMs
$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name gabNetworkSecurityGroupRuleSSH  -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow
# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName "gabdemo100rg" -Location 'Central US' -Name "gabNetworkSecurityGroup" -SecurityRules $nsgRuleRDP,$nsgRuleWinRM
# Create a virtual network card and associate with public IP address and NSG - Must be changed for every VM created
$nic = New-AzureRmNetworkInterface -Name gabNic -ResourceGroupName gabdemo100rg -Location 'Central US' -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

## Storage
# Make sure a default storage acount exists
Get-AzureRmStorageAccount

# If not, set it to one already created - session only
Set-AzureRmCurrentStorageAccount -ResourceGroupName 'gabdemo100rg' -StorageAccountName 'gabdemo100strg'

# Set it as default on the subscription - **Only works for ASM - ARM only sets current session
Set-AzureSubscription -SubscriptionName 'Nelmedia MPN' -CurrentStorageAccountName 'gabdemo100strg' 

# Or create a new one
New-AzureRmStorageAccount -ResourceGroupName gabdemo100rg -Name 'gabdemo100strg' -Location "Central US" -SkuName "Standard_LRS" -Kind "Storage"

# Verify the context
Get-AzureRmContext

# See options for creating VM's
Get-Help New-AzureQuickVM -Parameter * | Where-Object {$_.Required -eq $true}
Get-Help New-AzureVM -Parameter * | Where-Object {$_.Required -eq $true}
Get-Help New-AzureRmVM -Parameter * | Where-Object {$_.Required -eq $true}

Show-Command New-AzureQuickVM
Show-Command New-AzureRmVM

## Images
# HUB Images require E3/E5. Must have VS Sub or Azure EA "Dev/Test" checked to "see" some images.
#List images available in subscription for Quick Create
$images = Get-AzureVMImage | Group-Object Label | Select-Object Group | Sort-Object -Property PublishedDate -Descending | % { Select-Object -InputObject $_.Group[0] } | Sort-Object -Property Label
$global:index = -1
$images | Format-Table @{Name = 'index'; Expression = {$global:index; $global:index++}}, Label -AutoSize

# List images available in subscription for extended create (refined to Windows Server images only)
$location = 'Central US'
Get-AzureRmVMImagePublisher -Location $location | Where-Object -Property PublisherName -Like MicrosoftWindowsServer
$publisherName = 'MicrosoftWindowsServer'
Get-AzureRmVMImageOffer -Location $location -PublisherName $publisherName
$offer = 'WindowsServer'
Get-AzureRmVMImageSku -Location $location -PublisherName $publisherName -Offer $offer | Select-Object -Property 'Skus'

## Create the VM

# Linux VM creation "requires" a public SSH key with the name "id_rsa.pub" in the ".ssh" directory of your Windows user profile

# Deploy using a Template - samples here https://azure.microsoft.com/en-us/resources/templates/ https://github.com/Azure/azure-quickstart-templates 
# MS script can be downloaded from GitHub link
.\Deploy-AzureResourceGroup -ResourceGroupLocation 'Central US' -ArtifactStagingDirectory '201-vm-custom-script-windows' -UploadArtifacts
New-AzureRmResourceGroupDeployment -Name $name -ResourceGroupName gabdemo100RG -TemplateUri $templateUri
New-AzureRmResourceGroupDeployment -Name SimpleWinVM -ResourceGroupName gabdemo100rg -TemplateUri https://raw.githubusercontent.com/azure/azure-quickstart-templates/master/101-vm-simple-windows/azuredeploy.json
New-AzureRmResourceGroupDeployment -Name SimpleLinuxVM -ResourceGroupName gabdemo100rg -TemplateUri https://raw.githubusercontent.com/azure/azure-quickstart-templates/master/101-vm-simple-linux/azuredeploy.json
New-AzureRmResourceGroupDeployment -Name resourceLoopDeploy -ResourceGroupName gabdemo100rg -TemplateUri https://raw.githubusercontent.com/azure/azure-quickstart-templates/master/201-vm-copy-index-loops/azuredeploy.json
New-AzureRmResourceGroupDeployment -Name ActiveDirDeploy -ResourceGroupName gabdemo100rg -TemplateUri https://raw.githubusercontent.com/azure/azure-quickstart-templates/master/active-directory-new-domain-ha-2-dc/azuredeploy.json
New-AzureRmResourceGroupDeployment -Name WinRMVM -ResourceGroupName gabdemo100rg -TemplateUri https://raw.githubusercontent.com/azure/azure-quickstart-templates/master/201-vm-winrm-windows/azuredeploy.json
# Could also be a local file
New-AzureRmResourceGroupDeployment -Name "gabdemoWin1" -ResourceGroupName gabdemo100RG -TemplateFile "c:\temp\testdeploy.json" 
# Use Test to make sure the deployment would work
Test-AzureRmResourceGroupDeployment -Name "gabdemoWin1" -ResourceGroupName gabdemo100RG -TemplateFile "c:\temp\testdeploy.json" 

# Deploying NanoServer? Try this custom PoSH Module for easy deployments - https://msdnshared.blob.core.windows.net/media/2016/10/NanoServerAzureHelper_20160927.zip 
# Managing certain ARM VM's via API requires Key Vault creation (ie NanoServer cert must be imported into Key Vault)
New-AzureRmKeyVault -VaultName 'nanokeyvault' -ResourceGroupName 'gabdemo100rg' -Location 'Central US' -EnabledForTemplateDeployment -EnabledForDeployment -Sku standard 
Import-Module "C:\nano\NanoServerAzureHelper.psm1" -verbose
New-NanoServerAzureVM -Location "Central US" -VMName "nanoservervm" -AdminUsername "AdminNano" -VaultName "NanoKeyVault" -ResourceGroupName "gabdemo100rg" -Verbose

# Define a credential object
$cred = Get-Credential
$gabdemoNic = "/subscriptions/410b7108-c1d6-44a9-b604-e68c0c605064/resourceGroups/gabdemo100rg/providers/Microsoft.Network/networkInterfaces/gabNic"

## ASM ONLY
# Simple Windows VM Create - Use Location only once per Service	
New-AzureQuickVM -Windows -Name 'gabdemowin2016' -ServiceName 'gabdemo100RG' -ImageName $images[431].ImageName -Location 'Central US' -AdminUsername 'demouser' -Password '@zureRocks!'
# Next Windows VM - must not use Location or it will fail
New-AzureQuickVM -Windows -Name 'gabdemowin2016-2' -ServiceName 'gabdemo100RG' -ImageName $images[431].ImageName -AdminUsername 'demouser' -Password '@zureRocks!'
# Simple Linux VM Create
New-AzureQuickVM -Linux -ServiceName "gabdemo100rg" -Name "gabdemoCoreOS1" -ImageName "CoreOS Stable" -LinuxUser "RootMain" -Password "@azureRocks!" -Location "Central US"

# Create a virtual machine configuration
# Create the VM config - Windows
$vmConfig = New-AzureRmVMConfig -VMName gabdemowincore -VMSize Standard_A1 | Set-AzureRmVMOperatingSystem -Windows -ComputerName gabdemowincore -Credential $cred | Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter-Server-Core -Version latest | Add-AzureRmVMNetworkInterface -Id $gabdemoNic
# Create the VM - Windows
New-AzureRmVM -ResourceGroupName gabdemo100rg -Location 'Central US' -VM $vmConfig
# Create the VM config - Linux
$vmConfig = New-AzureRmVMConfig -VMName gabdemolinux -VMSize Standard_D1 | Set-AzureRmVMOperatingSystem -Linux -ComputerName gabdemolinux -Credential $cred -DisablePasswordAuthentication | Set-AzureRmVMSourceImage -PublisherName Canonical -Offer UbuntuServer -Skus 14.04.2-LTS -Version latest | Add-AzureRmVMNetworkInterface -Id $gabdemoNic
# Create the VM - Linux
New-AzureRmVM -ResourceGroupName gabdemo100rg -Location 'Central US' -VM $vmConfig
# Configure SSH Keys
$sshPublicKey = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"
Add-AzureRmVMSshPublicKey -VM $vmconfig -KeyData $sshPublicKey -Path "/home/azureuser/.ssh/authorized_keys"

# Get the Public IP
Get-AzureRmPublicIpAddress -ResourceGroupName gabdemo100rg | Select IpAddress

# Get RDP file
Get-AzureRemoteDesktopFile -Name "gabdemowin2016" -ServiceName "gabdemo100rg" -Launch

## Connect to new machine via Powersehll Remote
$hostName = 'gabdemowinwinrm.centralus.cloudapp.azure.com'
$winrmPort = '5986'
# Get the credentials of the machine
$cred = Get-Credential
# Connect to the machine
$soptions = New-PSSessionOption -SkipCACheck
Enter-PSSession -ComputerName $hostName -Port $winrmPort -Credential $cred -SessionOption $soptions -UseSSL
#Enter-PSSession -ConnectionUri $hostName":"$winrmport"/WSMAN" -Credential $cred
# Find out the Windows Sku
(Get-WmiObject -class Win32_OperatingSystem).Caption

# Delete Resource Group
Remove-AzureRmResourceGroup -Name gabdemo100RG


## Common and not-so-common commands
# Start a VM
Start-AzureRmVM -ServiceName "gabdemo100RG" -Name "gabdemowin2016"

# Stop a VM
Stop-AzureRmVM -ResourceGroupName "gabdemo100RG" -Name "gabdemowin2016" -Force
# Stop but stay provisioned ($$$)
Stop-AzureRmVM -ResourceGroupName "gabdemo100RG" -Name "gabdemowin2016" -StayProvisioned

# Get info about a machine
Get-AzureRmVM -ResourceGroupName $myResourceGroup -Name $myVM -DisplayHint Expand

# Add a data disk
$diskConfig = New-AzureRmDiskConfig -AccountType PremiumLRS -Location $location -CreateOption Empty -DiskSizeGB 128
$dataDisk = New-AzureRmDisk -DiskName "myDataDisk1" -Disk $diskConfig -ResourceGroupName $myResourceGroup
$vm = Get-AzureRmVM -Name $myVM -ResourceGroupName $myResourceGroup
Add-AzureRmVMDataDisk -VM $vm -Name "myDataDisk1" -VhdUri "https://mystore1.blob.core.windows.net/vhds/myDataDisk1.vhd" -LUN 0 -Caching ReadWrite -DiskSizeinGB 1 -CreateOption Empty
Update-AzureRmVM -ResourceGroupName $myResourceGroup -VM $vm

# Update a VM
$vm = Get-AzureRmVM -ResourceGroupName $myResourceGroup -Name $myVM
$vm.HardwareProfile.vmSize = "Standard_DS2_v2"
Update-AzureRmVM -ResourceGroupName $myResourceGroup -VM $vm

# Delete a VM
Remove-AzureRmVM -ResourceGroupName $myResourceGroup -Name $myVM

# Move a VM between Resource Groups
$sourceRG = "<sourceResourceGroupName>"
$destinationRG = "<destinationResourceGroupName>"
$vm = Get-AzureRmResource -ResourceGroupName $sourceRG -ResourceType "Microsoft.Compute/virtualMachines" -ResourceName "<vmName>"
$storageAccount = Get-AzureRmResource -ResourceGroupName $sourceRG -ResourceType "Microsoft.Storage/storageAccounts" -ResourceName "<storageAccountName>"
$diagStorageAccount = Get-AzureRmResource -ResourceGroupName $sourceRG -ResourceType "Microsoft.Storage/storageAccounts" -ResourceName "<diagnosticStorageAccountName>"
$vNet = Get-AzureRmResource -ResourceGroupName $sourceRG -ResourceType "Microsoft.Network/virtualNetworks" -ResourceName "<vNetName>"
$nic = Get-AzureRmResource -ResourceGroupName $sourceRG -ResourceType "Microsoft.Network/networkInterfaces" -ResourceName "<nicName>"
$ip = Get-AzureRmResource -ResourceGroupName $sourceRG -ResourceType "Microsoft.Network/publicIPAddresses" -ResourceName "<ipName>"
$nsg = Get-AzureRmResource -ResourceGroupName $sourceRG -ResourceType "Microsoft.Network/networkSecurityGroups" -ResourceName "<nsgName>"
Move-AzureRmResource -DestinationResourceGroupName $destinationRG -ResourceId $vm.ResourceId, $storageAccount.ResourceId, $diagStorageAccount.ResourceId, $vNet.ResourceId, $nic.ResourceId, $ip.ResourceId, $nsg.ResourceId
# Move a VM between subscriptions
Move-AzureRmResource -DestinationSubscriptionId "<destinationSubscriptionID>" -DestinationResourceGroupName $destinationRG -ResourceId $vm.ResourceId, $storageAccount.ResourceId, $diagStorageAccount.ResourceId, $vNet.ResourceId, $nic.ResourceId, $ip.ResourceId, $nsg.ResourceId

# Modify caching on disks
Set-AzureRmOSDisk
Set-AzureRmDataDisk

# Set ACL's
New-AzureAclConfig
Set-AzureAclConfig

# Change VM size
Set-AzureVMSize
Get-AzureVM -ServiceName gabdemo100RG ù | Set-AzureVMSize Largeù | Update-AzureVM

# Convert VHDX to VHD
Convert-VHD -Path c:\test\MY-VM.vhdx -DestinationPath c:\test\MY-NEW-VM.vhd -VHDType Fixed

# Upload VHD to Azure
$urlOfUploadedImageVhd = "https://mystorageaccount.blob.core.windows.net/mycontainer/myUploadedVHD.vhd"
Add-AzureRmVhd -ResourceGroupName $rgName -Destination $urlOfUploadedImageVhd -LocalFilePath "C:\Users\Public\Documents\Virtual hard disks\myVHD.vhd"

# Create a VM Provisioning Config
Add-AzureProvisioningConfig Windows -AdminUsername $adminUser -Password $adminPasword
$webvm1 = New-AzureVMConfig -Name Webvm1ù -InstanceSize Small -ImageName $vmimage
New-AzureVM -ServiceName $svcname -VMs $webvm1 -Location $location

# Publish DSC
Publish-AzureVMDscConfiguration 
Publish-AzureRmVMDscConfiguration

# create a context for account and key
$ctx=New-AzureStorageContext storage-account-name storage-account-key

# Create a New Container
New-AzureStorageContainer -Name $name -Permission off

# Get Endpoints
$storageAcc.PrimaryEndpoints.Blob.ToString() 

 # Get SAS Url
$sasUrl = New-AzureStorageContainerSASToken -Name $blobContainerName -Permission rwdl -Context $ctx -ExpiryTime (Get-Date).AddMonths(1) -FullUri

# Create cert for Nanoserver - requires makecert command
makecert -sky exchange -r -n "CN=nanoservexp.centralus.cloudapp.azure.com" -pe -a sha1 -len 2048 -ss My -sv myname-nanoservexp.pvk myname-nanoservexp.cer 
pvk2pfx -pvk myname-nanoservexp.pvk -pi <put the password here> -spc brisebois-nanoservexp.cer -pfx myname-nanoservexp.pfx