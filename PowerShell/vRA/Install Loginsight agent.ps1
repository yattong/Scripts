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

####### Set Variables

$dml = '\\mgmt.lprisoc1.kpmgmgmt.com\dml-isilon'
$dmlFilePath = 'VMware\vLoginsight'
$dmlUser = Read-Host "Enter Username for DML Access"
$dmlPassword = Read-Host -AsSecureString "Enter Password for $($dmlUser)"
$fileName = 'VMware-Log-Insight-Agent-3.6.0-4148343.msi'
$serverProtocol = 'cfapi'
$serverPort = '9543'
$caFileName = 'signingchain.cer'
$certPath = 'C:\ProgramData\VMware\Log Insight Agent\cert'
$configPath = 'C:\ProgramData\VMware\Log Insight Agent\liagent.ini'
$logPath = 'C:\ProgramData\VMware\Log Insight Agent\log'


"DEBUG - Using variables $dml and $fileName and $dmlUser and $dmlFilePath  `r`n"

# Validate installation files exist

try {
    if (!(Test-Path C:\Source\$filename)) {
        "Disabling Registry Key to disallow cached credentials `r`n"
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "disabledomaincreds" -Value "0"
       
        "Accessing DML... `r`n"
        net use $dml /user:$dmlUser $dmlPassword

        "Checking Source Folder Exists... `r`n"
        if (Test-Path C:\Source -Filter "TRUE") {
            "C:\Source already exists, ready to start copying files `r`n"
            } else {
            "C:\Source does not exist, creating Directory... `r`n"
            mkdir C:\Source
            }

        "Copying vLoginsight Agent Binaries... `r`n"
        Copy-Item $dml\$dmlFilePath\$fileName C:\Source

        "Copying CA certs... `r`n"
        If (!(Test-Path $certPath)) {
            "Creating certPath"
            mkdir "C:\ProgramData\VMware\Log Insight Agent\cert"
        } #end if
        Copy-Item $dml\$dmlFilePath\$caFileName $certPath

    } else {
        "Installation Files in Source Folder, continue to installation `r`n"

    }


    ######## Installation
    
    "Finding phsyical location be getting DNS servers `r`n"
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
        Write-Host "Server is in LPR  `r`n"
        $serverHost = 'prdvvrlisha01.kpmgmgmt.com'
    } else {
        Write-Host "Server is in IXE  `r`n"
        $serverHost = 'prdvvrlisha11.kpmgmgmt.com'
    }

    "Installing vLoginsight Agent... `r`n"
    Start-Process C:\Source\$fileName -ArgumentList "SERVERHOST=$serverHost SERVERPROTO=$serverProtocol SERVERPORT=$serverPort /qn" -wait

    $installResult = Get-WmiObject -Class Win32_Service -Filter "Name='LogInsightAgentService'"

    if ($installResult.Status -eq "OK") {
        "vLoginsight Agent installed successfully `r`n"
        exit 0

    } else {
        "vLoginsight Agent installation failed `r`n"
        $errorcount = $error.count
        "Error Count: $errorcount"
        "Contents of error: $error"
        $error[0].exception | fl * -for
        if ($DebugOn) {
            Start-Sleep -s 6000
        }
        exit 1
    }


    ######### Agent Configuration

    "Configuring vLoginsight agent... `r`n"

    "Configuring liagent.ini... `r`n"
    (Get-Content $configPath) -replace ";ssl=yes","ssl=yes`r`nssl_ca_path=$certPath\$caFileName" | Out-File $configPath -Encoding "UTF8" | Out-null

    sleep 5

    Add-Content $configPath "`r`n[winlog|Application]`r`nchannel=Application`r`n`r`n[winlog|Security]`r`nchannel=Security`r`n`r`n[winlog|System]`r`nchannel=System`r`n"  | Out-Null 

    "Restarting liagent service... `r`n"
    Restart-Service "LogInsightAgentService"

} catch {
    $error

} finally {
    "Enabling Registry Key to disallow cached credentials `r`n"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "disabledomaincreds" -Value "1"
    net use $dml /d

}