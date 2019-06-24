######################################################################################
#
# Author : Yattong Wu
# Date : 10 April 2018
# Version : 1.0
# Purpose : Restart a vRA Platform in the correct order
# Parameters : Server, Port, Username, Password, AppID, Project Name, Permission, User
#
######################################################################################

################################### Variables ########################################
# Add vRA VM names to arrays
$vRA_Appliances = @("PRDVVRAASHA01", "PRDVVRAASHA02")
$vRA_WebServers = @("PRDVVRAWSHA01", "PRDVVRAWSHA02")
$vRA_ManagerServers = @("PRDVVRAMSHA01", "PRDVVRAMSHA02")
$vRA_DEMs = @("PRDVVRADSHA01", "PRDVVRADSHA02")
$vRA_ProxyAgents = @("PRDVVRAPSHA01", "PRDVVRAPSHA02", "PRDVVRAPSHA03", "PRDVVRAPSHA11", "PRDVVRAPSHA12")
$vCenters = @("prdvvcsha01.kpmgmgmt.com", "prdvvcsha02.kpmgmgmt.com")

################################### Loading Modules ##################################
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

################################### Functions ########################################
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

################################### Execute ########################################

# Read vCenter Username
$vCenterUsername = Read-Host "Please enter Username for vCenter : $($vCenter)"
# Read vCenter Password with a little bit of security ;)
$vCenterPassword = Read-Host -AsSecureString "Please enter Password for vCenter : $($vCenter)"
# Convert Password
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($vCenterPassword)
$vCenterPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

for each ($vCenter in $vCenters){
    # Connect to vCenter
    Write-Host "Connecting to vCenters"
    Connect-VIServer $vCenter -User $vCenterUsername -Password $vCenterPassword -ErrorAction Stop 
}

## Should find active node and leave until last.

# Shutdown Proxy Agents
for each ($vRA_ProxyAgent in $vRA_ProxyAgents){
    if ((Get-VM $vRA_ProxyAgent).PowerState -eq "PoweredOn"){
        Write-Host -ForegroundColor Cyan "Shutting Down : $($vRA_ProxyAgent)"
	    Shutdown-VMGuest $vRA_ProxyAgent -confirm:$false
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_ProxyAgent) is already Shutdown"
    }
}

# Shutdown DEM Orchestrators
for each ($vRA_DEM in $vRA_DEMs){
	if ((Get-VM $vRA_DEM).PowerState -eq "PoweredOn"){
        Write-Host -ForegroundColor Cyan "Shutting Down : $($vRA_DEM)"
	    Shutdown-VMGuest $vRA_DEM -confirm:$false
    } else {
        Write-Host -ForegroundColor Cyan "$($vRA_DEM) is already Shutdown"
    }
}