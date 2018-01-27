<#
.SYNOPSIS
    Provides the administrative user a windows form where Windows Server Container can be managed.
.DESCRIPTION
    This script creates a form that requires a container host as input. Based on the specified container host it will query the containers of the specified 
    container host and container images. This provides the administrative user with the options like start, stop, connect, and remove containers and much more.
.NOTES     
    Author: Darryl van der Peijl
    Contact: DarrylvanderPeijl@outlook.com  
    Date published: 27-10-2015  
    Version: 1.0
.LINK   
    http://www.DarrylvanderPeijl.nl
#>

#Function to load the form
Function Load-Form {
    $global:Computername = $TextBoxComputer.Text
    $Form.Controls.Add($ButtonGet)
    $Form.Controls.Add($ButtonImportContainerImage)
    $Form.Controls.Add($ButtonCreateContainer)
    $Form.Controls.Add($ButtonNewContainerImage)
    $Form.Controls.Add($ButtonStop)
    $Form.Controls.Add($ButtonStart)
    $Form.Controls.Add($ButtonConnectNetadapter)
    $Form.Controls.Add($ButtonAddNetadapter)
    $Form.Controls.Add($ButtonGetNetworkInfo)
    $Form.Controls.Add($ButtonImportContainerOSImage)
    $Form.Controls.Add($ButtonExportContainerImage)
    $Form.Controls.Add($ButtonRemoveContainerImage)
    $Form.Controls.Add($ButtonShowImages)
    $Form.Controls.Add($ButtonRemove)
    $Form.Controls.Add($DataGridView)
    $Form.Controls.Add($LabelDarryl)
    $Form.Controls.Add($LabelTwitter)
    $Form.Controls.Add($LinkLabelTwitter)
    $Form.Controls.Add($TextBoxComputer)
    $Form.Controls.Add($GroupBoxContainers)
    $Form.Controls.Add($GroupBoxUser)
    $Form.Controls.Add($GroupBoxStartStopRemove)
 	$Form.ShowDialog()
 }

#Function to reset the form
Function Refresh-Form {
If ($DataGridView.RowCount -ne 0) {
$DataGridView.Rows.Clear()
}
}

#Function to get containers
Function Get-Wincontainers {
    Refresh-Form
        Try {
            $Containers = Get-Container -ComputerName $Computername
            If ($Containers -ne $Null) {
                ForEach ($Container in $Containers) {
                    $DataGridView.Rows.Add($Container.Name,$Container.state,$Container.uptime,$Container.parentimage.name,$Container.id) | Out-Null
                }
            }
            Else {
                  [Windows.Forms.MessageBox]::Show(“Cannot find any containers on the specified container host.`n Specify another container host.`n”, “Cannot find any containers.”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Warning) 
                 }
        }
        Catch {
            [Windows.Forms.MessageBox]::Show(“Error receiving containers.`nFailed to get containers for the specified host.”, “Error receiving containers”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
            
        }
        
}

#Function to stop the container
Function Stop-WinContainer {
    Param (
    [String]$ContainerName,
    [String]$ContainerID
    )
    $Verifcation = [Windows.Forms.MessageBox]::Show(“Are you sure that you want to STOP the container named $ContainerName”, “Stop Container”, [Windows.Forms.MessageBoxButtons]::YesNo, [Windows.Forms.MessageBoxIcon]::Warning)
    If ($Verifcation -eq "Yes") {
        Try {
            $Container = Get-Container -Name $ContainerName -ComputerName $Computername | where {$_.id -eq $ContainerID}
            Stop-Container -Container $Container -Confirm:$False          
        }
        Catch {
            [Windows.Forms.MessageBox]::Show(“Error while stopping container $Containername.`n$_”, “Error while stopping container”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    Get-Wincontainers
}

#Function to Start the container
Function Start-WinContainer {
    Param (
    [String]$ContainerName,
    [String]$ContainerID
    )
        Try {
            $Container = Get-Container -Name $ContainerName -ComputerName $Computername | where {$_.id -eq $ContainerID}
            Start-Container -Container $Container -Confirm:$False
            }
        Catch {
            [Windows.Forms.MessageBox]::Show(“Error while starting container $ContainerName.`n$_”, “Error while starting container”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
        }
        Get-Wincontainers
}

#Function to connect netadapter
Function Connect-WinNetadapter {
    Param (
    [String]$ContainerName,
    [String]$ContainerID
    )
        Try {
            $Container = Get-Container -Name $ContainerName -ComputerName $Computername | where {$_.id -eq $ContainerID}
            $ContainerNetworkAdapter = Get-ContainerNetworkAdapter -Container $Container| Out-GridView -Title "Select Container Network Adapter" -OutputMode Single
            $VMSwitch = Get-VMSwitch -ComputerName $Computername | Out-GridView -Title "Select Virtual Switch" -OutputMode Single
            
            if ($ContainerName -and $ContainerNetworkAdapter -and $VMSwitch){     
            Get-ContainerNetworkAdapter -Container $Container | where {$_.id -eq $ContainerNetworkAdapter.Id} | Connect-ContainerNetworkAdapter -SwitchName $VMSwitch.name
            }
            Else{Write-warning "Missing Parameters for connect netadapter, action canceled"} 
            }
        Catch {
            [Windows.Forms.MessageBox]::Show(“Failed connecting networkadapter to virtual switch.`nThis function does not work for remote computers yet (bug?)`n$_”, “Error”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
              }
}

#Function to add netadapter to container
Function Add-WinNetadapter {
    Param (
    [String]$ContainerName,
    [String]$ContainerID
    )
        Try {
            $Container = Get-Container -Name $ContainerName -ComputerName $Computername | where {$_.id -eq $ContainerID}
            $Netadaptername = [Microsoft.VisualBasic.Interaction]::InputBox("Enter netadapter name", "Name", "NIC") 
            $VMSwitch = Get-VMSwitch -ComputerName $Computername | Out-GridView -Title "Select Virtual Switch" -OutputMode Single
            
            if ($Container -and $Netadaptername -and $VMSwitch){ 
            Add-ContainerNetworkAdapter -Container $Container -SwitchName $VMSwitch.name -Name $Netadaptername  
            
            }
            Else{Write-warning "Missing Parameters for adding netadapter to container, action canceled"} 
            }
        Catch {
            [Windows.Forms.MessageBox]::Show(“Failed connecting networkadapter to virtual switch.`nThis function does not work for remote computers yet (bug?)`n$_”, “Error”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
              }
}

#Function to Remove the container
Function Remove-WinContainer {
    Param (
    [String]$ContainerName,
    [String]$ContainerID
    )
    $Verifcation = [Windows.Forms.MessageBox]::Show(“Are you sure that you want to REMOVE the container named $ContainerName”, “REMOVE Container”, [Windows.Forms.MessageBoxButtons]::YesNo, [Windows.Forms.MessageBoxIcon]::Warning)
    If ($Verifcation -eq "Yes") {
        Try {
            $Container = Get-Container -Name $ContainerName -ComputerName $Computername | where {$_.id -eq $ContainerID}
            Remove-Container -Container $Container -Force
                    }
        Catch {
            [Windows.Forms.MessageBox]::Show(“Error while removing container $Containername.`n$_”, “Error while removing container”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    Get-Wincontainers
}

#Function to Create the container
Function Create-WinContainer {
    Param (
    [String]$ContainerName,
    [String]$ContainerID
    )
         Try {
         $ContainerName = $null;$ContainerImage = $null;$VMSwitch = $null
         $ContainerName = [Microsoft.VisualBasic.Interaction]::InputBox("Specify container name", "Name", "ContainerName") 
         $ContainerImage = Get-ContainerImage -ComputerName $Computername | Out-GridView -Title "Select Container Image" -OutputMode Single
         $VMSwitch = Get-VMSwitch -ComputerName $Computername | Out-GridView -Title "Select Virtual Switch" -OutputMode Single


         if ($ContainerName.Length -gt 0 -and $ContainerImage -and $VMSwitch){  
         $container = New-Container -Name $ContainerName -ContainerImageName $ContainerImage.name -SwitchName $VMSwitch.Name -ComputerName $Computername
         }
         Else{Write-warning "Missing Parameters for creating container, action canceled"}
          
        }
        Catch {
            [Windows.Forms.MessageBox]::Show(“Error while creating container $Containername.`n$_”, “Error while creating container”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
           }
     Get-Wincontainers
    }

#Function to get container images
Function Get-WinContainerImages {
         Try {
         $ContainerImages = Get-ContainerImage -ComputerName $Computername
         $ContainerImages | Out-GridView -Title "Container Images"
              }
        Catch {
             [Windows.Forms.MessageBox]::Show(“Error while receiving container images `n$_”, “Error while receiving container images”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
        }
        }
  
#Function to Create container image
Function Create-WinContainerImage {
    Param (
    [String]$ContainerName,
    [String]$ContainerID
    )
         Try {
         $Container = Get-Container -Name $ContainerName -ComputerName $Computername | where {$_.id -eq $ContainerID}
         $SourceContainerImage = Get-ContainerImage -Name $Container.ParentImage.Name -ComputerName $Computername

         $ContainerImageName = [Microsoft.VisualBasic.Interaction]::InputBox("Specify New Image name", "Image Name", "$($SourceContainerImage.name)")
         $ContainerImagePublisher = [Microsoft.VisualBasic.Interaction]::InputBox("Specify Publisher name", "Publisher Name", "$($SourceContainerImage.Publisher)")
         $ContainerImageVersion = [Microsoft.VisualBasic.Interaction]::InputBox("Specify image version", "Image Name", "$($SourceContainerImage.Version.ToString())")

         if ($ContainerImageName -and $ContainerImagePublisher -and $ContainerImageVersion){     
         $Containerimage = New-ContainerImage -Container $Container -Name $ContainerImageName -Publisher $ContainerImagePublisher -Version $ContainerImageVersion 
         }
         Else{Write-warning "Missing Parameters for creating container image, action canceled"}
        }
        Catch {
            [Windows.Forms.MessageBox]::Show(“Error while creating container image `n$_”, “Error creating container image”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
        }
    }

#Function to Remove container Images
Function Remove-WinContainerImage {
         Try {

         $ContainerImage = Get-ContainerImage -ComputerName $Computername | Out-GridView -Title "Select Container Image to Remove" -OutputMode Single
         if ($ContainerImage){    
         $Verifcation = [Windows.Forms.MessageBox]::Show(“Are you sure that you want to REMOVE the container image $($Containerimage.name)?”, “REMOVE Container image”, [Windows.Forms.MessageBoxButtons]::YesNo, [Windows.Forms.MessageBoxIcon]::Warning)
         If ($Verifcation -eq "Yes") {

          
         Remove-ContainerImage -Image $ContainerImage -Force
         }
         Else{Write-warning "Missing Parameters for removing container image, action canceled"}
         }
        }
        Catch {
            [Windows.Forms.MessageBox]::Show(“Error while removing container image `n$_”, “Error removing container image”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
        }
    }

#Function to Import container Images
Function Import-WinContainerImage {
         Try {

        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.initialDirectory = "MyComputer"
        $OpenFileDialog.filter = "APPX (*.APPX)| *.APPX"
        $OpenFileDialog.ShowDialog() | Out-Null

        $ContainerImagePath = $OpenFileDialog.FileName
        
        if ($ContainerImagePath){    
         Import-ContainerImage -Path $ContainerImagePath -ComputerName $Computername -Confirm:$False
         }
         Else{Write-warning "Missing Parameters for removing container image, action canceled"}
         
        }
        Catch {
            [Windows.Forms.MessageBox]::Show(“Error importing container image `n$_”, “Error importing container image”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
              }
}

#Function to Import container Images
Function Install-WinContainerOSImage {
         Try {

        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.initialDirectory = "MyComputer"
        $OpenFileDialog.filter = "WIM (*.WIM)| *.WIM"
        $OpenFileDialog.ShowDialog() | Out-Null

        $ContainerImagePath = $OpenFileDialog.FileName
        
        if ($ContainerImagePath){    
         Install-ContainerOSImage -WiMPath $ContainerImagePath -Force
         }
         Else{Write-warning "Missing Parameters for installing container OS image, action canceled"}
         
        }
        Catch {
            [Windows.Forms.MessageBox]::Show(“Error while installing container OS image `n$_”, “Error installing container image”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
        
    }
}

#Function to Export container Images
Function Export-WinContainerImage {
         Try {

        $ContainerImage = Get-ContainerImage -ComputerName $Computername | Out-GridView -Title "Select Container Image" -OutputMode Single
        
        $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
        $foldername.rootfolder = "MyComputer"
        if($foldername.ShowDialog() -eq "OK")
        {
        $Path = $foldername.SelectedPath
        }

         if ($ContainerImage -and $Path){    
         $Image = Get-ContainerImage -Name $Containerimage.Name -ComputerName $Computername
         Export-ContainerImage -Image $ContainerImage -Path $Path
                         
         }
         Else{Write-waring "Missing Parameters for exporting container image, action canceled"}
         
        }
        Catch {
            [Windows.Forms.MessageBox]::Show(“Error while exporting container image `n$_”, “Error while exporting container image”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
        
    }
}

#Function to Start the container
Function Get-WinContainerNetworkInfo {
    Param (
    [String]$ContainerName,
    [String]$ContainerID
    )
        Try {
            $Container = Get-Container -Name $ContainerName -ComputerName $Computername | where {$_.id -eq $ContainerID}
            $NetworkInfo = Invoke-Command -ContainerId $container.id -ScriptBlock {Get-NetIPAddress | ? AddressFamily -eq IPv4 | Select-Object ifIndex,IPv4Address,InterfaceAlias} -ErrorAction SilentlyContinue
            if ($NetworkInfo){
            $NetworkInfo | Out-GridView -Title "Network Information"
            }
            else{
            throw $error[0].Exception
            }
          }
        Catch {
            [Windows.Forms.MessageBox]::Show(“Error while getting network information of container $ContainerName.`nThis function does not work remote (yet?).`n`n$_”, “Error getting IP of container”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
        }
                Get-Wincontainers
}

#TextBoxComputer MouseHover event to show a tooltip about the required information
$TextBoxComputer_MouseHover= {
    $Tip = "Enter the name of the container host"
    $ToolTip.SetToolTip($This,$Tip)
}

#DataGridView CurrentCellChanged event to enable buttons based on the selection
$DataGridView_CurrentCellChanged= {

    If ($DataGridView.CurrentRow -ne $Null) {
        $ContainerState = $DataGridView.CurrentRow.Cells[1].Value
         If ($ContainerState -eq "Running") {
            $ButtonStop.visible = $True
            $ButtonStop.enabled = $True
            $ButtonStop.BackColor = "OrangeRed"
            $ButtonRemove.Enabled = $False
            $ButtonNewContainerImage.Enabled = $False
            $ButtonConnectNetadapter.Enabled = $True
            $ButtonAddNetadapter.Enabled = $True
            $ButtonGetNetworkInfo.Enabled = $True

        }
        else {
        $ButtonStop.visible = $False
        $ButtonStart.visible = $True
        $ButtonStart.enabled = $True
        $ButtonRemove.Enabled = $True
        $ButtonNewContainerImage.Enabled = $True
        $ButtonConnectNetadapter.Enabled = $True
        $ButtonAddNetadapter.Enabled = $True
        $ButtonGetNetworkInfo.Enabled = $False
        }
    }
}

#LinkLabelBlog event to open a browser session to my blog
$LinkLabelBlog_OpenLink= {
    [System.Diagnostics.Process]::start($LinkLabelBlog.text)
}

#LinkLabelTwitter OpenLink event to open a browser session to my twitter page
$LinkLabelTwitter_OpenLink= {
    [System.Diagnostics.Process]::start("http://twitter.com/DarrylvdPeijl")
}

#Load Assemblies
[Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
[Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

#Create ToolTip
$ToolTip = New-Object System.Windows.Forms.ToolTip

#Create ErrorProvider
$ErrorProvider = New-Object System.Windows.Forms.ErrorProvider
$ErrorProvider.BlinkStyle = "NeverBlink"

#Create Form
$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(580,500)  
$Form.MinimumSize = New-Object System.Drawing.Size(580,500)
$Form.MaximumSize = New-Object System.Drawing.Size(580,500)
$Form.SizeGripStyle = "Hide"
$Form.Text = "Windows Server Container Manager"
$Form.ControlBox = $True
#$Form.TopMost = $True
$Form.Add_Shown({$Form.Activate(); $TextBoxComputer.focus()})

#Create ButtonGet
$ButtonGet = New-Object System.Windows.Forms.Button
$ButtonGet.Location = New-Object System.Drawing.Size(20,55)
$ButtonGet.Size = New-Object System.Drawing.Size(150,25)
$ButtonGet.Text = "Get Containers"
$ButtonGet.TabIndex = 0
$ButtonGet.add_Click({Get-Wincontainers})

#Import Container Button
$ButtonImportContainerImage = New-Object System.Windows.Forms.Button
$ButtonImportContainerImage.Location = New-Object System.Drawing.Size(240,50)
$ButtonImportContainerImage.Size = New-Object System.Drawing.Size(150,25)
$ButtonImportContainerImage.Text = "Import Container Image"
$ButtonImportContainerImage.Enabled = $true
$ButtonImportContainerImage.add_Click({Import-WinContainerImage})

#Export Container Button
$ButtonExportContainerImage = New-Object System.Windows.Forms.Button
$ButtonExportContainerImage.Location = New-Object System.Drawing.Size(390,50)
$ButtonExportContainerImage.Size = New-Object System.Drawing.Size(150,25)
$ButtonExportContainerImage.Text = "Export Container Image"
$ButtonExportContainerImage.Enabled = $True
$ButtonExportContainerImage.add_Click({Export-WinContainerImage})

#Create ButtonCreateContainer
$ButtonCreateContainer = New-Object System.Windows.Forms.Button
$ButtonCreateContainer.Location = New-Object System.Drawing.Size(240,80)
$ButtonCreateContainer.Size = New-Object System.Drawing.Size(150,25)
$ButtonCreateContainer.Text = "Create Container"
$ButtonCreateContainer.Enabled = $True
$ButtonCreateContainer.add_Click({Create-WinContainer})
$ButtonCreateContainer.BackColor = "LightGreen"

#Create ButtonShowImages
$ButtonShowImages = New-Object System.Windows.Forms.Button
$ButtonShowImages.Location = New-Object System.Drawing.Size(390,80)
$ButtonShowImages.Size = New-Object System.Drawing.Size(150,25)
$ButtonShowImages.Text = "Show Images"
$ButtonShowImages.Enabled = $True
$ButtonShowImages.add_Click({Get-WinContainerImages})

#Create ButtonInstallContainerOSImage
$ButtonImportContainerOSImage = New-Object System.Windows.Forms.Button
$ButtonImportContainerOSImage.Location = New-Object System.Drawing.Size(240,25)
$ButtonImportContainerOSImage.Size = New-Object System.Drawing.Size(150,25)
$ButtonImportContainerOSImage.Text = "Install Container OS Image"
$ButtonImportContainerOSImage.Enabled = $True
$ButtonImportContainerOSImage.add_Click({Install-WinContainerOSImage})

#Create ButtonRemoveContainerImage
$ButtonRemoveContainerImage = New-Object System.Windows.Forms.Button
$ButtonRemoveContainerImage.Location = New-Object System.Drawing.Size(390,25)
$ButtonRemoveContainerImage.Size = New-Object System.Drawing.Size(150,25)
$ButtonRemoveContainerImage.Text = "Remove Container Image"
$ButtonRemoveContainerImage.Enabled = $True
$ButtonRemoveContainerImage.add_Click({Remove-WinContainerImage})

#Create ButtonStop
$ButtonStop = New-Object System.Windows.Forms.Button
$ButtonStop.Location = New-Object System.Drawing.Size(20,350)
$ButtonStop.Size = New-Object System.Drawing.Size(150,25)
$ButtonStop.Text = "Stop"
$ButtonStop.Enabled = $False
$ButtonStop.add_Click({Stop-WinContainer $DataGridView.CurrentRow.Cells[0].Value $DataGridView.CurrentRow.Cells[4].Value})

#Create ButtonStart
$ButtonStart = New-Object System.Windows.Forms.Button
$ButtonStart.Location = New-Object System.Drawing.Size(20,350)
$ButtonStart.Size = New-Object System.Drawing.Size(150,25)
$ButtonStart.Text = "Start"
$ButtonStart.Enabled = $False
$ButtonStart.add_Click({$DataGridView.CurrentRow.Cells[1].Value = "Starting";Start-WinContainer $DataGridView.CurrentRow.Cells[0].Value $DataGridView.CurrentRow.Cells[4].Value})

#Create ButtonConnectNetadapter
$ButtonConnectNetadapter = New-Object System.Windows.Forms.Button
$ButtonConnectNetadapter.Location = New-Object System.Drawing.Size(180,350)
$ButtonConnectNetadapter.Size = New-Object System.Drawing.Size(150,25)
$ButtonConnectNetadapter.Text = "Connect Netadapter"
$ButtonConnectNetadapter.Enabled = $False
$ButtonConnectNetadapter.add_Click({Connect-WinNetadapter $DataGridView.CurrentRow.Cells[0].Value $DataGridView.CurrentRow.Cells[4].Value})

#Create ButtonAddNetadapter
$ButtonAddNetadapter = New-Object System.Windows.Forms.Button
$ButtonAddNetadapter.Location = New-Object System.Drawing.Size(180,375)
$ButtonAddNetadapter.Size = New-Object System.Drawing.Size(150,25)
$ButtonAddNetadapter.Text = "Add Netadapter"
$ButtonAddNetadapter.Enabled = $false
$ButtonAddNetadapter.add_Click({Add-WinNetadapter $DataGridView.CurrentRow.Cells[0].Value $DataGridView.CurrentRow.Cells[4].Value})

#Create ButtonGetNetworkInfo
$ButtonGetNetworkInfo = New-Object System.Windows.Forms.Button
$ButtonGetNetworkInfo.Location = New-Object System.Drawing.Size(180,400)
$ButtonGetNetworkInfo.Size = New-Object System.Drawing.Size(150,25)
$ButtonGetNetworkInfo.Text = "Get Network Info"
$ButtonGetNetworkInfo.Enabled = $false
$ButtonGetNetworkInfo.add_Click({Get-WinContainerNetworkInfo $DataGridView.CurrentRow.Cells[0].Value $DataGridView.CurrentRow.Cells[4].Value})

#Create ButtonRemove
$ButtonRemove = New-Object System.Windows.Forms.Button
$ButtonRemove.Location = New-Object System.Drawing.Size(390,400)
$ButtonRemove.Size = New-Object System.Drawing.Size(150,25)
$ButtonRemove.Text = "Remove"
$ButtonRemove.Enabled = $False
$ButtonRemove.add_Click({Remove-Wincontainer $DataGridView.CurrentRow.Cells[0].Value $DataGridView.CurrentRow.Cells[4].Value})

#Create ButtonNewContainerImage
$ButtonNewContainerImage = New-Object System.Windows.Forms.Button
$ButtonNewContainerImage.Location = New-Object System.Drawing.Size(20,375)
$ButtonNewContainerImage.Size = New-Object System.Drawing.Size(150,25)
$ButtonNewContainerImage.Text = "New Container Image"
$ButtonNewContainerImage.Enabled = $False
$ButtonNewContainerImage.add_Click({Create-Wincontainerimage $DataGridView.CurrentRow.Cells[0].Value $DataGridView.CurrentRow.Cells[4].Value})

#Create DataGriView1
$DataGridView = New-Object System.Windows.Forms.DataGridView
$DataGridView.Location = New-Object System.Drawing.Size(20,140)
$DataGridView.Size = New-Object System.Drawing.Size(520,170)
$DataGridView.AllowUserToAddRows = $False
$DataGridView.AllowUserToDeleteRows = $False
$DataGridView.AllowUserToResizeRows = $False
$DataGridView.MultiSelect = $false
$DataGridView.Anchor = "Top, Bottom, Left, Right"
$DataGridView.ScrollBars = "Vertical"
$DataGridView.BackGroundColor = "White"
$DataGridView.ColumnCount = 5
$DataGridView.ColumnHeadersVisible = $True
$DataGridView.Columns[0].Name = "Name"
$DataGridView.Columns[0].MinimumWidth = 20
$DataGridView.Columns[0].Width = 130
$DataGridView.Columns[1].Name = "State"
$DataGridView.Columns[1].MinimumWidth = 30
$DataGridView.Columns[1].Width = 60
$DataGridView.Columns[2].Name = "Uptime"
$DataGridView.Columns[2].MinimumWidth = 50
$DataGridView.Columns[2].Width = 80
$DataGridView.Columns[3].Name = "Image"
$DataGridView.Columns[3].MinimumWidth = 130
$DataGridView.Columns[3].Width = 130
$DataGridView.Columns[4].Name = "ID"
$DataGridView.Columns[4].MinimumWidth = 20
$DataGridView.Columns[4].Width = 117
$DataGridView.ReadOnly = $True
$DataGridView.RowHeadersVisible = $False
$DataGridView.SelectionMode = "FullRowSelect"
$DataGridView.add_CurrentCellChanged($DataGridView_CurrentCellChanged)

#Create GroupBoxClose
$GroupBoxClose = New-Object System.Windows.Forms.GroupBox
$GroupBoxClose.Location = New-Object System.Drawing.Size(380,310) 
$GroupBoxClose.Size = New-Object System.Drawing.Size(170,50) 
$GroupBoxClose.Text = "Close"

#Create GroupBoxContainers
$GroupBoxContainers = New-Object System.Windows.Forms.GroupBox
$GroupBoxContainers.Location = New-Object System.Drawing.Size(10,120) 
$GroupBoxContainers.Size = New-Object System.Drawing.Size(540,200) 
$GroupBoxContainers.Text = "Containers"

#Create GroupBoxActions
$GroupBoxRemoteActions = New-Object System.Windows.Forms.GroupBox
$GroupBoxRemoteActions.Location = New-Object System.Drawing.Size(230,10) 
$GroupBoxRemoteActions.Size = New-Object System.Drawing.Size(320,100) 
$GroupBoxRemoteActions.Text = "Actions"

#Create Start/Stop/Remove Groupbox
$GroupBoxStartStopRemove = New-Object System.Windows.Forms.GroupBox
$GroupBoxStartStopRemove.Location = New-Object System.Drawing.Size(10,330) 
$GroupBoxStartStopRemove.Size = New-Object System.Drawing.Size(540,105) 
$GroupBoxStartStopRemove.Text = "Start / Stop / Connect / Remove"

#Create GroupBoxUser
$GroupBoxUser = New-Object System.Windows.Forms.GroupBox
$GroupBoxUser.Location = New-Object System.Drawing.Size(10,10) 
$GroupBoxUser.Size = New-Object System.Drawing.Size(170,80) 
$GroupBoxUser.Text = "Container Host"

#Create LabelDarryl
$LabelDarryl = New-Object System.Windows.Forms.Label
$LabelDarryl.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$LabelDarryl.Location = New-Object System.Drawing.Size(20,444) 
$LabelDarryl.Text = "Darryl van der Peijl"
        
#Create LabelTwitter
$LabelTwitter = New-Object System.Windows.Forms.Label
$LabelTwitter.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$LabelTwitter.Location = New-Object System.Drawing.Size(340,444) 
$LabelTwitter.Size = New-Object System.Drawing.Size(111,23)
$LabelTwitter.Text = "Follow me on twitter:"

#Create LinkLabelTwitter
$LinkLabelTwitter = New-Object System.Windows.Forms.LinkLabel
$LinkLabelTwitter.Font = New-Object System.Drawing.Font("Tahoma",8.25,0,3,0)
$LinkLabelTwitter.Location = New-Object System.Drawing.Size(449,444) 
$LinkLabelTwitter.Size = New-Object System.Drawing.Size(90,23)
$linkLabelTwitter.Text = "@DarrylvdPeijl"
$LinkLabelTwitter.add_Click($LinkLabelTwitter_OpenLink)

#Create TextBoxComputer
$TextBoxComputer = New-Object System.Windows.Forms.TextBox
$TextBoxComputer.Location = New-Object System.Drawing.Size(20,30)
$TextBoxComputer.Size = New-Object System.Drawing.Size(150,25)
$TextBoxComputer.Text = "localhost"
$TextBoxComputer.add_MouseHover($TextBoxComputer_MouseHover)
$TextBoxComputer.Add_TextChanged({$global:Computername = $TextBoxComputer.Text})


if (!(Get-WindowsFeature -Name "Containers" | Where Installed)){
[Windows.Forms.MessageBox]::Show(“The Container feature is not installed on this computer, install the feature and try again.”, “Error”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error);
exit
}

#Load form
Load-Form