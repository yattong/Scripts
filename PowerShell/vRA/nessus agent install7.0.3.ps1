######################################################################################
#
# Author : Yattong Wu
# Date : 21 June 2018
# Version : 1.0
# Purpose : Install Nessus Agent
# Parameters : Username, Password
#
######################################################################################

### Clear out errors
$error.clear()

####### Set Variables

$dml = '\\mgmt.lprisoc1.kpmgmgmt.com\dml-isilon'
$dmlFilePath = 'Tenable\Agents'
$fileName = "NessusAgent-7.0.3-x64.msi"
$NessusKey = "292d52a0cd11ea03ab3986b3bd65f69c423e8dc3c328595a1ccf4a21d68aecfc"
$NessusServer = "MANvTNMSHA01.kpmgmgmt.com"
$dmlUser = Read-Host "Enter Username for DML Access"
$dmlPassword = Read-Host -AsSecureString "Enter Password for $($dmlUser)"


"DEBUG - Using variables $dml and $fileName and $dmlUser and $dmlFilePath"

try {
    # Validate installation files exist

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

        Write-Output "Copying Nessus Agent Binaries... `r`n"
        Copy-Item $dml\$dmlFilePath\$fileName C:\Source | Out-Null
    
        Write-Output "Copying KPMG Cert... `r`n"
        Copy-Item $dml\$dmlFilePath\RootCA.pem C:\Source | Out-Null

    

    } else {
        Write-Output "Installation Files in Source Folder, continue to installation `r`n"
    

    } 

    ######### Agent Installation


    Write-Output "Installing Nessus Agent... `r`n"
    if ((Get-WmiObject Win32_ComputerSystem).Domain -eq "kpmgmgmt.com") {
        Write-Output "kpmgmgmt.com domain detected... `r`n"
        $NessusGroup = "Management"

    } else { #non mgmt domain machine
        Write-Output "This isn't a KPMGMGMT.COM machine, detecting environment... `r`n"
        if ((hostname).Substring(9,1) -eq "P" -or (hostname).substring(0,3) -eq "PRD") {
            Write-Output "This is a PRD machine..."
            $NessusGroup = "Production"
        } 
        elseif ((hostname).Substring(9,1) -eq "U" -or (hostname).substring(0,3) -eq "UAT") {
            Write-Output "This is a UAT machine... `r`n"
            $NessusGroup = "UAT"
        }
        elseif ((hostname).Substring(9,1) -eq "T" -or (hostname).substring(0,3) -eq "TST") {
            Write-Output "This is a TST machine... `r`n"
            $NessusGroup = "Test"
        } 
        elseif ((hostname).Substring(9,1) -eq "D" -or (hostname).substring(0,3) -eq "DEV") {
            Write-Output "This is a DEV machine... `r`n"
            $NessusGroup = "Dev"
        }
    }

    "Assigned Nessus Group - $NessusGroup"
     Write-Output "Starting Agent install `r`n"
     Start-Process C:\Source\$fileName -ArgumentList "NESSUS_GROUPS=$NessusGroup NESSUS_SERVER=$NessusServer NESSUS_KEY=$NessusKey ca-path=C:\Source\RootCA.pem /qn" -wait
     #Start-Process C:\Source\$fileName -ArgumentList "NESSUS_GROUPS=Management NESSUS_SERVER=MANvTNMSHA01.kpmgmgmt.com NESSUS_KEY=292d52a0cd11ea03ab3986b3bd65f69c423e8dc3c328595a1ccf4a21d68aecfc  /qn" -wait
     "Copying RooCA Certificate as .inc file to Nessus plugins directory"
     Copy-Item -Path "C:\source\RootCA.pem" -Destination "C:\programdata\Tenable\Nessus Agent\nessus\plugins\Custom_ca.inc"
     Write-Output "Linking Agent `r`n"
     Start-Process 'C:\Windows\System32\cmd.exe' -ArgumentList "/C `"C:\Program Files\Tenable\Nessus Agent\nessuscli.exe`" agent link --key=$NessusKey --host=$NessusServer --port=8834 --groups=$NessusGroup" -wait
        

    $installResult = Get-WmiObject -Class Win32_Service -Filter "Name='Tenable Nessus Agent'"
    if ($installResult.Status -eq "OK") {
        Write-Output "Nessus Agent installed Successfully `r`n"

        $agentdir = 'C:\Program Files\Tenable\Nessus Agent'
        cd $agentdir

        $LinkingResult = .\nessuscli.exe agent status
        $LinkingResult
        if (($LinkingResult) -contains "[info] [agent] Linked to MANvTNMSHA01.kpmgmgmt.com:8834") {
            Write-Output "Nessus Agent Successfully Linked to MANvTNMSHA01 `r`n"
            exit 0
        } else {
            Write-Output "Nessus Agent Linking Failed. `r`n"
            exit 1
        }
    }

} catch {
    "Entering error catch statement..."
    $error
    exit 1

} finally {

    Write-Output "Enabling Registry Key to disallow cached credentials `r`n"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "disabledomaincreds" -Value "1"

    net use $dml /d

}
