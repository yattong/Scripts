#############################
# 
# Author : Yattong Wu
# Date : 28/2/18
# Version : 1.0
# Purpose : Restart the Test vRA Platform in the correct order
#
#############################

## Variables
# Change vRA VM names
$vRA_Appliance1 = "PRDVVRAASHA01"
$vRA_Appliance2 = "PRDVVRAASHA02"
$vRA_WebServer1 = "PRDVVRAWSHA01"
$vRA_WebServer2 = "PRDVVRAWSHA02"
$vRA_ManagerServer1 = "PRDVVRAMSHA01"
$vRA_ManagerServer2 = "PRDVVRAMSHA02"
$vRA_DEM1 = "PRDVVRADSHA01"
$vRA_DEM2 = "PRDVVRADSHA02"
$vRA_ProxyAgent1 = "PRDVVRAPSHA01"
$vRA_ProxyAgent2 = "PRDVVRAPSHA02"
$vRA_ProxyAgent3 = "PRDVVRAPSHA03"
$vRA_ProxyAgent4 = "PRDVVRAPSHA11"
$vRA_ProxyAgent5 = "PRDVVRAPSHA12"

# Check if vm snapin is loaded
if (!(Get-Module -Name VMware.VimAutomation.Core) -and (Get-Module -ListAvailable -Name VMware.VimAutomation.Core)) {  
    Write-Output "loading the VMware Core Module..."
    Import-Module -Name VMware*.VimAutomation.core
    Import-Module -Name VMware*.VimAutomation.Storage
    Import-Module -Name VMware*.VimAutomation.SDK
    Import-Module -Name VMware*.VimAutomation.Vds
    Import-Module -Name VMware*.VimAutomation.HA
    Import-Module -Name VMware*.VimAutomation.CIS.core
    }

# Power On Function
Function PowerOn ($VMName)
{
	Write-Host "Starting : " $VMName 
	Start-VM -VM $VMName -RunAsync -Confirm:$false | Out-Null
 
	Write-Host "Checking : " $VMName 
	do{
		Start-Sleep -Seconds 5;
		$VM = Get-VM $VMName
		$ToolsStatus = $VM.extensionData.Guest.ToolsStatus;
		Write-Host "Status : " $ToolsStatus 
	}while($ToolsStatus -ne "toolsOk");
	Write-Host -ForegroundColor Green "Done Booting : " $VMName 
}
 
Function Shutdown ($VMName)
{
	Write-Host "Shutting Down : " $VMName
	$VM = Get-VM -Name $VMName
	if($VM.PowerState -eq "PoweredOn"){
		Shutdown-VMGuest -VM $VMName -confirm:$false | Out-Null
		do{
			Start-Sleep -Seconds 5;
			$VM = Get-VM $VMName
			Write-Host "Status : " $VM.PowerState
		}while($VM.PowerState -eq "PoweredOn");
	}
	Write-Host -ForegroundColor Green "Done Shutting Down : " $VMName 
}
 
# Connect to vCenter(s)
#$vCenter = Read-Host "vCenter"
$vCenter = "prdvvcsha01.kpmgmgmt.com"
$vCenter2 = "prdvvcsha02.kpmgmgmt.com"
 
# Read vCenter Username
$vCenterUsername = Read-Host "vCenter Username"
# Read vCenter Password with a little bit of security ;)
$vCenterPassword = Read-Host -AsSecureString "vCenter Password"
# Convert Password
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($vCenterPassword)
$vCenterPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
# Connect to vCenter
Write-Host "Connecting to vCenter"
Connect-VIServer $vCenter -User $vCenterUsername -Password $vCenterPassword -ErrorAction Stop | Out-Null
Connect-VIServer $vCenter2 -User $vCenterUsername -Password $vCenterPassword -ErrorAction Stop -Force | Out-Null
 
## Shut Down VMs
# Shutdown Proxy Agents
if($vRA_ProxyAgent5){
    if ((Get-VM $vRA_ProxyAgent5).PowerState -eq "PoweredOn"){
        Write-Host -ForegroundColor Cyan "Shutting Down : $($vRA_ProxyAgent5)"
	    Shutdown-VMGuest $vRA_ProxyAgent5 -confirm:$false
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_ProxyAgent5) is already Shutdown"
    }
}
if($vRA_ProxyAgent4){
    if ((Get-VM $vRA_ProxyAgent4).PowerState -eq "PoweredOn"){
        Write-Host -ForegroundColor Cyan "Shutting Down : $($vRA_ProxyAgent4)"
	    Shutdown-VMGuest $vRA_ProxyAgent4 -confirm:$false
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_ProxyAgent4) is already Shutdown"
    }
}
if($vRA_ProxyAgent3){
    if ((Get-VM $vRA_ProxyAgent3).PowerState -eq "PoweredOn"){
        Write-Host -ForegroundColor Cyan "Shutting Down : $($vRA_ProxyAgent3)"
	    Shutdown-VMGuest $vRA_ProxyAgent3 -confirm:$false
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_ProxyAgent3) is already Shutdown"
    }
}
if($vRA_ProxyAgent2){
	if ((Get-VM $vRA_ProxyAgent2).PowerState -eq "PoweredOn"){
        Write-Host -ForegroundColor Cyan "Shutting Down : $($vRA_ProxyAgent2)"
	    Shutdown-VMGuest $vRA_ProxyAgent2 -confirm:$false
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_ProxyAgent2) is already Shutdown"
    }
}
if($vRA_ProxyAgent1){
    if ((Get-VM $vRA_ProxyAgent1).PowerState -eq "PoweredOn"){
    	Shutdown $vRA_ProxyAgent1
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_ProxyAgent1) is already Shutdown"
    }
}

# Shutdown DEM Orchestrators
if($vRA_DEM2){
	if ((Get-VM $vRA_DEM2).PowerState -eq "PoweredOn"){
        Write-Host -ForegroundColor Cyan "Shutting Down : $($vRA_DEM2)"
	    Shutdown-VMGuest $vRA_DEM2 -confirm:$false
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_DEM2) is already Shutdown"
    }
}
if($vRA_DEM1){
    if ((Get-VM $vRA_DEM1).PowerState -eq "PoweredOn"){
    	Shutdown $vRA_DEM1
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_DEM1) is already Shutdown"
    }
}

# Shutdown IAAS Manager
if($vRA_ManagerServer2){
	if ((Get-VM $vRA_ManagerServer2).PowerState -eq "PoweredOn"){
        Write-Host -ForegroundColor Cyan "Shutting Down : $($vRA_ManagerServer2)"
	    Shutdown-VMGuest $vRA_ManagerServer2 -confirm:$false
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_ManagerServer2) is already Shutdown"
    }
}
if($vRA_ManagerServer1){
    if ((Get-VM $vRA_ManagerServer1).PowerState -eq "PoweredOn"){
    	Shutdown $vRA_ManagerServer1
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_ManagerServer1) is already Shutdown"
    }
}

# Shutdown IAAS Web
if($vRA_WebServer2){
    if ((Get-VM $vRA_WebServer2).PowerState -eq "PoweredOn"){
        Write-Host -ForegroundColor Cyan "Shutting Down : $($vRA_WebServer2)"
	    Shutdown-VMGuest $vRA_WebServer2 -confirm:$false
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_WebServer2) is already Shutdown"
    }
}
if($vRA_WebServer1){
    if ((Get-VM $vRA_WebServer1).PowerState -eq "PoweredOn"){
    	Shutdown $vRA_WebServer1
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_WebServer1) is already Shutdown"
    }
}

#  Shutdown vRA Appliances
if($vRA_Appliance2){
    if ((Get-VM $vRA_Appliance2).PowerState -eq "PoweredOn"){
        Write-Host -ForegroundColor Cyan "Shutting Down : $($vRA_Appliance2)"
	    Shutdown-VMGuest $vRA_Appliance2 -confirm:$false
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_Appliance2) is already Shutdown"
    }
}
if($vRA_Appliance1){
    if ((Get-VM $vRA_Appliance1).PowerState -eq "PoweredOn"){
    	Shutdown $vRA_Appliance1
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_Appliance1) is already Shutdown"
    }
}

##
Write-Host -ForegroundColor Cyan "Test vRA Platform shutdown completed successfully"

 
## Starting VMs
# Power On vRA Appliances
if($vRA_Appliance1){
    if ((Get-VM $vRA_Appliance1).PowerState -eq "PoweredOff"){
	    PowerOn $vRA_Appliance1
	    Write-Host "Waiting for 2min"
	    Sleep 120
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_Appliance1) is already Powered On"
    }
}
if($vRA_Appliance2){
	if ((Get-VM $vRA_Appliance2).PowerState -eq "PoweredOff"){
        Start-VM $vRA_Appliance2
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_Appliance2) is already Powered On"
    }
}

# Power On IAAS Web Servers
if($vRA_WebServer1){
    if ((Get-VM $vRA_WebServer1).PowerState -eq "PoweredOff"){
	    PowerOn $vRA_WebServer1  
	    Write-Host "Waiting for 5min"
	    Sleep 300
    } else {
         Write-Host -ForegroundColor Cyan "$($vRA_WebServer1) is already Powered On"
    }
}
if($vRA_WebServer2){
    if ((Get-VM $vRA_WebServer2).PowerState -eq "PoweredOff"){
	    Start-VM $vRA_WebServer2
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_WebServer2) is already Powered On"
    }
}


# Power On IAAS Manager
if($vRA_ManagerServer1){
    if ((Get-VM $vRA_ManagerServer1).PowerState -eq "PoweredOff"){
	    PowerOn $vRA_ManagerServer1
	    Write-Host "Waiting for 5min"
	    Sleep 300
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_ManagerServer1) is already Powered On"
    }
}
if($vRA_ManagerServer2){
    if ((Get-VM $vRA_ManagerServer2).PowerState -eq "PoweredOff"){
		Start-VM $vRA_ManagerServer2
	} else {
        Write-Host -ForegroundColor Cyan "$($vRA_ManagerServer2) is already Powered On"
    }
}

# Power On DEM Orchestrators
if($vRA_DEM1){
    if ((Get-VM $vRA_DEM1).PowerState -eq "PoweredOff"){
	    PowerOn $vRA_DEM1
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_DEM1) is already Powered On"
    }
}
if($vRA_DEM2){
    if ((Get-VM $vRA_DEM2).PowerState -eq "PoweredOff"){
    	Start-VM $vRA_DEM2
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_DEM2) is already Powered On"
    }
}

# Power On Proxy Agents
if($vRA_ProxyAgent1){
    if ((Get-VM $vRA_ProxyAgent1).PowerState -eq "PoweredOff"){
    	PowerOn $vRA_ProxyAgent1
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_ProxyAgent1) is already Powered On"
    }
}
if($vRA_ProxyAgent2){
    if ((Get-VM $vRA_ProxyAgent2).PowerState -eq "PoweredOff"){
    	PowerOn $vRA_ProxyAgent2
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_ProxyAgent2) is already Powered On"
    }
}
if($vRA_ProxyAgent3){
    if ((Get-VM $vRA_ProxyAgent3).PowerState -eq "PoweredOff"){
    	PowerOn $vRA_ProxyAgent3
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_ProxyAgent3) is already Powered On"
    }
}
if($vRA_ProxyAgent4){
    if ((Get-VM $vRA_ProxyAgent4).PowerState -eq "PoweredOff"){
    	PowerOn $vRA_ProxyAgent4
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_ProxyAgent4) is already Powered On"
    }
}
if($vRA_ProxyAgent5){
    if ((Get-VM $vRA_ProxyAgent5).PowerState -eq "PoweredOff"){
    	PowerOn $vRA_ProxyAgent5
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_ProxyAgent5) is already Powered On"
    }
}
