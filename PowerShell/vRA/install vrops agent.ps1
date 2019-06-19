######################################################################################
#
# Author : Yattong Wu
# Date : 21 June 2018
# Version : 1.0
# Purpose : Install vROps Agent
# Parameters : Username, Password
#
######################################################################################

### Clear out errors
$error.clear()


####### Check if agent already installed
$installResult = Get-WmiObject -Class Win32_Service -Filter "Name='End Point Operations Management Agent'"
if ($installResult.Status -eq "OK") {
    Write-Output "vROps EPOps Agent installed successfully `r`n"
    exit 0
} else {

    ####### Set Variables
    
    $dmlUser = Read-Host "Enter Username for DML Access"
    $dmlPassword = Read-Host -AsSecureString "Enter Password for $($dmlUser)"
    $dml = '\\mgmt.lprisoc1.kpmgmgmt.com\dml-isilon'
    $dmlFilePath = 'VMware\vROps'
    $fileName = 'vRealize-Endpoint-Operations-Management-Agent-x86-64-win-6.6.0-5654169.exe'
    $agentUsername = 'epopsAdmin'
    $agentPassword = Read-Host -AsSecureString "Enter Password for EpopsAdmin"
    $serverThumbprint = 'EF:D9:5F:ED:FE:79:54:00:84:9C:95:14:A2:8C:C2:B6:A1:8B:4C:C8'

    "DEBUG - Using variables $dml and $fileName and $dmlUser and $dmlFilePath `r`n"
}

try {
    ####### Validate installation files exist

    if (!(Test-Path C:\Source\$filename)) {
        Write-Output "Installation Files not in Source Folder, connecting to repo for files `r`n"

        Write-Output "Disabling Registry Key to disallow cached credentials `r`n"
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "disabledomaincreds" -Value "0"
       
        Write-Output "Accessing DML... `r`n"
        net use $dml /user:$dmlUser $dmlPassword

        Write-Output "Checking Source Folder Exists... `r`n"
        if (Test-Path C:\Source -Filter "TRUE") {
            Write-Output "C:\Source already exists, ready to start copying files `r`n"
        } else {
            Write-Output "C:\Source does not exist, creating Directory... `r`n"
            mkdir C:\Source
        }

        Write-Output "Copying vROps Agent Binaries... `r`n"
        Copy-Item $dml\$dmlFilePath\$fileName C:\Source

    } else {
        Write-Output "Installation Files in Source Folder, continue to installation `r`n"
    
    } 

    ########## Installation 

    Write-Output "Finding phsyical location be getting DNS servers `r`n"
    try {            
        $Networks = Get-WmiObject Win32_NetworkAdapterConfiguration  -EA Stop | ? {$_.IPEnabled}            
    } catch {            
        Write-Warning "Error occurred while querying NIC `r`n"            
        Continue            
    }
           
    foreach ($Network in $Networks) {              
        $DNSServers  = $Network.DNSServerSearchOrder                           
    }      
        $FirstDNSServer = $DNSServers[0]

    if ($FirstDNSServer -eq "10.174.100.101"){
        Write-Host "Server is in LPR `r`n"
        $serverAddress = 'prdvvreposha99.kpmgmgmt.com'
    } else {
        Write-Host "Server is in IXE `r`n"
        $serverAddress = 'prdvvreposha00.kpmgmgmt.com'
    }

    Write-Output "Installing vROps EPOps Agent... `r`n"
    Start-Process C:\Source\$fileName -ArgumentList "-serverAddress $serverAddress -username $agentUsername -password $agentPassword -serverCertificateThumbprint $serverThumbprint /verysilent" -Wait

    $installResult = Get-WmiObject -Class Win32_Service -Filter "Name='End Point Operations Management Agent'"
    if ($installResult.Status -eq "OK") {
        Write-Output "vROps EPOps Agent installed successfully `r`n"
        exit 0
    } else {
        Write-Output "vROps EPOps Agent installation failed `r`n"
        exit 1
    }

} catch {
    "Entering error catch statement..."
    $Error

} finally {
    Write-Output "Enabling Registry Key to disallow cached credentials `r`n"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "disabledomaincreds" -Value "1"
    net use $dml /d

}