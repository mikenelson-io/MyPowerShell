#VMware Tools download
https://packages.vmware.com/tools/releases/latest/windows/x64/index.html
# Download the .EXE
# Extract the tools
	VMware-tools-10.0.9-3917699-x86_64.exe /a
	Copy pvscsi\*.* and vmxnet3\NDIS6\*.*
	
New-NanoServerImage -deploymenttype guest -edition standard -mediapath d: -targetpath c:\nano\vhd\nanodemo1.vhd -computername nanodemo1 -enableremotemanagementport -AdministratorPassword $NanoPass -DriverPath c:\nano\vmtools_drivers

# To run on ESXi or Workstation/Fusion
# Convert VHD or VHDX to VMDK - use StarWind V2V Converter
# VM settings:
#  hardware version 11
#  Guest Win 2016
#  VMXNET3 adapter
#  VMware Paravirtual (pvscsi) SCSI controller
#  Do not add hard disk
#  Make sure VM Boot options are set to "EFI" is converted from VHDX (Gen2)


#Nano as Hyper-V host on VMware
#enable nested virtualization - latest Win 10 builds
# expose hardware assisted virtualization to the guest OS
# advanced config parameter "hypervisor.cpuid.v0" = FALSE