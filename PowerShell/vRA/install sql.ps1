$DebugOn = $true
<#
####DEBUG VALUES#######

$SQLInstanceName            = "ISQL01"
$SQLVersion                  = "SQLServer2014Standard"
$SAPlainPassword              = "Password123456789"
$SQLCollation            = "Latin1_General_CI_AS"
$SQLAgentAccountName = ""
$SQLServiceAccountName = ""

$SQLAgentAccountPlainPassword = ""
$SQLServiceAccountPlainPassword  = ""
$DMLPassword = ""
$DMLUsername = ""
$ProdDomainPlainPassword          
$TestDomainPlainPassword
##### END DEBUG VALUES######
#>

#########################################################
# These values will be passed from vRealize App Services:
$RootPath                     = "\\mgmt.lprisoc1.kpmgmgmt.com\dml-isilon"
$InstanceName                 = $SQLInstanceName
$SQLVer                       = $SQLVersion
$SQLCollation                 = $SQLCollation
$ProdDomainPassword           = $ProdDomainPlainPassword | ConvertTo-SecureString -AsPlainText -Force
$TestDomainPassword           = $TestDomainPlainPassword | ConvertTo-SecureString -AsPlainText -Force

#########################################################

"####DEBUG LOGGING - VALUES####"
"RootPath : $RootPath"
"InstanceName : $InstanceName"
"SQLVer : $SQLVer"
"SQLCollation : $SQLCollation"

$error.Clear()
try {

If ($SQLVersion.length -lt 1) {
    Write-Output "SQL Version not right"
   #Start-Sleep -s 3600
   exit 1
}
If ($SQLInstanceName.length -lt 1) {
    Write-Output "SQL Instance not right"
    #Start-Sleep -s 3600
   exit 1
}
If ($SQLCollation.length -lt 1) {
    Write-Output "SQL Collation not right"
    #Start-Sleep -s 3600
   exit 1
}
If ($DebugOn) {
    "Adding Administrator into sysadmins role for troubleshooting"
    $Requestor = '"Administrator"'#"darwin"'
}
#Else {
#   $Requestor = '"darwin"' 
#}

$ServerName              = $env:COMPUTERNAME
# servername format vDBSREL01P001
if ($ServerName.substring(9,1) -eq "T") {
    $Requestor               = $Requestor + ' "KPMGTEST\RESTST_SHA_DBSADMINS_LEVEL3" "RESTST_SHA_DBSADMINS_LEVEL2"'
    $Domain                  = "kpmgtest.com"   
}
elseif ($ServerName.substring(9,1) -eq "D") {
    $Requestor               = $Requestor + ' "KPMGTEST\RESDEV_SHA_DBSADMINS_LEVEL3" "RESDEV_SHA_DBSADMINS_LEVEL2"'
    $Domain                  = "kpmgtest.com"
}
elseif ($ServerName.substring(9,1) -eq "U") {
    $Requestor               = $Requestor + ' "KPMGPROD\RESUAT_SHA_DBSADMINS_LEVEL3"'
    $Domain                  = "kpmgprod.com"
}
elseif ($ServerName.substring(9,1) -eq "P") {
    $Requestor               = $Requestor + ' "KPMGPROD\RESPRD_SHA_DBSADMINS_LEVEL3" "RESPRD_SHA_DBSADMINS_LEVEL2"'
    $Domain                  = "kpmgprod.com"
}

$NetBiosDomainName       = $Domain.split(".")[0]

"Converting the key property from a string into an array for configuring the decryption key"

$arrayPasswordKey = @()
for ($i = 0; $i -lt 16; $i++) {
    $arrayPasswordKey += $passwordEncryptionKey.substring(($i*2),2)
}

"Defining the key"
[Byte[]] $key                 = $arrayPasswordKey

"Extracting the Service Account details from XML file"
$props = [xml](Get-Content "C:\VRMGuestAgent\site\workitem.xml")
$xmlResult = $props.workitem.properties.property | where {$_.name -eq "kpmg.sql.sqlagentaccountname"} |Select value
$SQLAgentAccountName = $xmlResult.value
$xmlResult = $props.workitem.properties.property | where {$_.name -eq "kpmg.sql.sqlserviceaccountname"} |Select value
$SQLServiceAccountName = $xmlResult.value
$xmlResult = $props.workitem.properties.property | where {$_.name -eq "kpmg.sql.sqlserviceaccountpassword"} |Select value
$SQLServiceAccountPassword = $xmlResult.value
$xmlResult = $props.workitem.properties.property | where {$_.name -eq "kpmg.sql.sqlagentaccountpassword"} |Select value
$SQLAgentAccountPassword = $xmlResult.value
$xmlResult = $props.workitem.properties.property | where {$_.name -eq "kpmg.sql.sapassword"} |Select value
$SAEncryptedPassword = $xmlResult.value
$xmlResult = $props.workitem.properties.property | where {$_.name -eq "kpmg.sql.backupPassword"} |Select value
$BackupPasswordEncrypted = $xmlResult.value

If ($DebugOn) {
    "DEBUG - Using account values: $SQLServiceAccountName,$SQLAgentAccountName,$SQLServiceAccountPassword,$SQLAgentAccountPassword,$ProdDomainAccount,$TestDomainAccount"
    "DEBUG - Using $arrayPasswordKey"
}
# Format volumes removed from here 20-07-2017 under KCHG0037825


"Starting Account and Password decryption:"
"Retrieving SQL Service Account Details"
$SQLServiceAccountPassword      = $SQLServiceAccountPassword | ConvertTo-SecureString -Key $key
$SQLServiceBSTR                 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SQLServiceAccountPassword)
$SQLServiceAccountPlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($SQLServiceBSTR)

"Retrieving SQL Agent Account Details"
$SQLAgentAccountPassword        = $SQLAgentAccountPassword | ConvertTo-SecureString -Key $key
$SQLAgentBSTR                   = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SQLAgentAccountPassword)
$SQLAgentAccountPlainPassword   = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($SQLAgentBSTR)

"Retrieving SA Password"
$SAPassword                     = $SAEncryptedPassword | ConvertTo-SecureString -Key $key
$SABSTR                         = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SAPassword)
$SAPlainPassword                = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($SABSTR)

"Retrieving Backup Password"
$BackupPassword                 = $BackupPasswordEncrypted | ConvertTo-SecureString -Key $key
$BackupBSTR                     = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($BackupPassword )
$BackupPlainPassword            = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BackupBSTR)

#Setup a folder to store installation logs
$SupportFolder = "S:\SQLInstallSupport\"
$chkfolder = Test-Path  "$($SupportFolder)"

if(!$chkfolder)
{
    mkdir  "$($SupportFolder)"
}

if ($DebugOn) {
    "DEBUG is on. Creating Log file."
    $LogFile = "$SupportFolder\SQLinstall.log"
    Start-Transcript -path $LogFile
}

"Map a network Drive to SQL Source"

"Checking for existing mapped drives and removing to avoid conflicting credentials"
$Drives = Get-PSDrive -PSProvider FileSystem
Foreach ($Drive in $Drives) {
    $DriveName = $Drive.Name
    If ($DriveName.Length -gt 1) {
        "Removing PSDrive $DriveName"
        Remove-PSDrive -Name $DriveName
    }
}
"Checking output from net use"
get-smbMapping
"Deleting any mapped drive to dml"
If (get-smbmapping |where {$_.RemotePath -eq $RootPath}) {
   "Removing Mapped Drive $RootPath"
    remove-smbmapping -RemotePath $RootPath -Force
} #end if


$pass = $DMLPassword |ConvertTo-SecureString -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential($DMLUsername,$pass)

"Relaxing network credentials setting"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "disabledomaincreds" -Value "0"
"Mapping SQLSource Drive"
$DriveMappedSuccess = $false
$DriveMapAttempts = 0
while(!$DriveMappedSuccess -and $DriveMapAttempts -lt 5) {
    "Mapping SQLSource Drive"
    New-PSDrive -Name SQLSource -PSProvider FileSystem -Root "$RootPath\Microsoft\SQLServer" -Credential $Cred
    If (Test-Path SQLSource:\ -PathType Container) {
        $DriveMappedSuccess = $true
        "SQLSource Drive mapped ok"
    }
    Else { 
        "SQLSource Drive not mapped, sleeping for 5 secs before a retry"
        "Testing connectivity:"
        test-netconnection mgmt.lprisoc1.kpmgmgmt.com -Port 445
        Start-Sleep -s 60
        $DriveMapAttempts++
    }
} #end while

If (!$DriveMappedSuccess) {
    throw "####### ERROR, cannot map drive to SQL Source, terminating script ######"
}
$InstallSSMS = $false
$SetSQL2016Flags = $false
"Determine install source location:"

    if ($SQLVer -eq "SQLServer2014Developer") {
        "SQL Version SQLServer2014Developer found"
        $loc = 'SQLSource:\2014\Developer\'
    }
    elseif ($SQLVer -eq "SQLServer2014Enterprise") {
        "SQL Version SQLServer2014Enterprise found"
        $loc = 'SQLSource:\2014\Enterprise\'
    }
    elseif ($SQLVer -eq "SQLServer2014Standard") {
        "SQL Version SQLServer2014Standard found"
        $loc = 'SQLSource:\2014\Standard\'
    }
    elseif ($SQLVer -eq "SQLServer2014EnterpriseSPLA") {
        "SQL Version SQLServer2014EnterpriseSPLA found"
        $loc = 'SQLSource:\2014\SPLA\Enterprise\'
    }
    elseif ($SQLVer -eq "SQLServer2014StandardSPLA") {
        "SQL Version SQLServer2014StandardSPLA found"
        $loc = 'SQLSource:\2014\SPLA\Standard\'
    }
    elseif ($SQLVer -eq "SQLServer2016EnterpriseSPLA") {
        "SQL Version SQLServer2016EnterpriseSPLA found"
        $loc = 'SQLSource:\2016\SPLA\Enterprise\'
        $InstallSSMS = $true
        $SetSQL2016Flags = $true
    }
    elseif ($SQLVer -eq "SQLServer2016StandardSPLA") {
        "SQL Version SQLServer2016StandardSPLA found"
        $loc = 'SQLSource:\2016\SPLA\Standard\'
        $InstallSSMS = $true
        $SetSQL2016Flags = $true
    }
    elseif ($SQLVer -eq "SQLServer2016Enterprise") {
        "SQL Version SQLServer2016Enterprise found"
        $loc = 'SQLSource:\2016\Enterprise\'
        $InstallSSMS = $true
        $SetSQL2016Flags = $true
    }
    elseif ($SQLVer -eq "SQLServer2016Standard") {
        "SQL Version SQLServer2016Standard found"
        $loc = 'SQLSource:\2016\Standard\'
        $InstallSSMS = $true
        $SetSQL2016Flags = $true
    }
    elseif ($SQLVer -eq "SQLServer2016Developer") {
        "SQL Version SQLServer2016Developer found"
        $loc = 'SQLSource:\2016\Developer\'
        $InstallSSMS = $true
        $SetSQL2016Flags = $true
    }

    "DEBUG - loc is set to $loc"
    "Checking for the presence of The SQL Native Client and uninstalling"
    # This step is required to prevent SQL installing on C: drive as the Client is classed as a component of SQL Server"
    $app = Get-WmiObject -Class Win32_Product | Where-Object { 
        $_.Name -match "Microsoft SQL Server 2012 Native Client" 
    }

    if ($app) {
        "Uninstalling SQL Client"
        $app.Uninstall()
        "Uninstall Complete"
    }

    if ($InstallSSMS) {
        "Installing SSMS 17.5"
        Start-Process "SQLSource:\SSMS17.5\SSMS-Setup-ENU.exe" -WorkingDirectory c:\ -verb RunAs -Wait -ArgumentList " /install /quiet /norestart"
        "Finished Installing SSMS 17.5"
    }

#Create Configuration Install File

New-PSDrive -Name loc -Root $loc -PSProvider FileSystem
Set-Location $loc

#$file is the contents of the configuration file once variables have been replaced
$file = Get-Content "$($loc)\ConfigInstall\ConfigurationFile.ini"

if($InstanceName -eq "" -or $InstanceName -eq $null)
{
    $InstanceName = "MSSQLSERVER"
}
#Determine if Default instance is used
If ($InstanceName -eq "MSSQLSERVER") {
    $DefaultInstanceName = $true
}

$file = Foreach-Object {$file -replace "##INSTANCENAME", "$($InstanceName)"}
$file = Foreach-Object {$file -replace "##SVCACCOUNT", "$LocalSQLAccount"}
$file = Foreach-Object {$file -replace "##SVCPASSWORD", "$LocalSQLAccountPassword"}
$file = Foreach-Object {$file -replace "##SQLCOLLATION", "$($SQLCollation)"}
$file = Foreach-Object {$file -replace "##REQUESTOR", "$($Requestor)"}


#Create configuration file for each install
Set-Content "$($SupportFolder)\ConfigurationFile_$($ServerName)_$($InstanceName).ini" $file -Force
sleep -s 5

#Perform the install
if ($DebugOn) {
    "DEBUG - $($loc)Setup.exe -ArgumentList /ConfigurationFile=$($SupportFolder)ConfigInstall\ConfigurationFile_$($ServerName)_$($InstanceName).ini"
}
"Running the SQL Setup.exe...."
Start-Process "$($loc)Setup.exe" -WorkingDirectory c:\ -verb RunAs -Wait -ArgumentList "/ConfigurationFile=$($SupportFolder)\ConfigurationFile_$($ServerName)_$($InstanceName).ini /IAcceptSQLServerLicenseTerms /SAPWD=""$($SAPlainPassword)"""
"Setup.exe has finished"

"Copying the installation logs to Config directory"
$today = (Get-Date).ToString('yyyyMMdd')
$SQLSubFolders = Get-Item -Path "C:\Program Files\Microsoft SQL Server\1*" | sort -Property Name -Descending
foreach ($SQLSubFolder in $SQLSubFolders) {
    If (Get-ChildItem -Path $SQLSubFolder | Where-Object { $_.Name -match 'Setup Bootstrap' }) {
        "Found the Setup Bootstrap Folder at $($SQLSubFolder.FullName)"
        break
    }
} #end foreach

$SQLLog = "$($SQLSubFolder.FullName)\Setup Bootstrap\Log\$today*\Summary*"

Copy-Item -Path "$SQLLog" $SupportFolder -Recurse

"Start RPC service if not already started"
Start-Service "Remote Procedure Call (RPC) Locator"
"RPC Service Started"

"Adding DBA Groups to local Remote Desktop Users group"
$ArrayOfPermissions = $Requestor.split(" ")
$ArrayOfDomainObjects = @()
foreach ($Object in $ArrayOfPermissions) {
    If ($Object.indexOf("\") -gt 0) {
        "$Object - Adding group (In NetBIOS format) to the array for adding to local group"
        $ArrayOfDomainObjects += $Object.split("\")[1].replace('"','') #strip off any speech marks
    }
}

foreach ($GroupToAdd in $ArrayOfDomainObjects) {
    "Adding $GroupToAdd to Local Administrators group"
    $LocalAdminGroup = [ADSI]"WinNT://$env:COMPUTERNAME/Administrators"
    $Members = @($LocalAdminGroup.psbase.Invoke("Members"))
    #Populate the $MemberNames array with all the user ID's
    $MemberNames = @()
    $Members | ForEach-Object {$MemberNames += $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null);}

    #Check to see if the user is already a member, and add if not.
    #This check is required to avoid an exception if the users is already a member
    #Doing this in a loop with a try and catch statement to avoid errors where the DC is not recognising the user since being created

    $AddADUserSuccess = $false
    $RetryCount = 0
    while(!$AddADUserSuccess -and $RetryCount -lt 5) {
        $RetryCount++
         try {
            if (-Not $MemberNames.Contains($GroupToAdd)) {
                "Adding now"
                 ([ADSI]"WinNT://$env:COMPUTERNAME/Administrators,group").Add("WinNT://$Domain/$GroupToAdd")
                 $AddADUserSuccess = $true #If no error produced
            } #End If
         } #End Try
         Catch {
             "AD account $User not yet found on $Domain, sleeping then retry in 1 min"
             $error.clear()
             sleep -s 60
         } #End Catch
     } #End While
} #end for each $grouptoadd

"Import SQL Module"
if ((Test-Path "C:\Program Files (x86)\Microsoft SQL Server\$($SQLSubFolder.Name)\Tools\PowerShell\Modules\SQLPS"))
{
    import-module "C:\Program Files (x86)\Microsoft SQL Server\$($SQLSubFolder.Name)\Tools\PowerShell\Modules\SQLPS" -DisableNameChecking -ErrorAction Stop
}
if ((Test-Path "D:\Program Files (x86)\Microsoft SQL Server\$($SQLSubFolder.Name)\Tools\PowerShell\Modules\SQLPS"))
{
    import-module "D:\Program Files (x86)\Microsoft SQL Server\$($SQLSubFolder.Name)\Tools\PowerShell\Modules\SQLPS" -DisableNameChecking -ErrorAction Stop
}
"The following modules are loaded:"
Get-Module

"Clearing Import-Module SQLAS Errors"
$Error.Clear() #Required to clear error loading SQLAS CMDlets

"Loading SQLWMIManagement"
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement") | out-null
$SMOWmiserver = New-Object ('Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer') "$env:COMPUTERNAME"          


"Calculating Resource Limits"
$ComputerSystem = Get-WmiObject Win32_ComputerSystem
$MaximumMemory = [math]::truncate($ComputerSystem.TotalPhysicalMemory /1MB - 6144)
If ($MaximumMemory -lt 0) {
    "Not enough Memory to allocate 6GB to OS, dropping to 1GB"
    $MaximumMemory = [math]::truncate($ComputerSystem.TotalPhysicalMemory /1MB - 1024)
}

$Processors = Get-WmiObject Win32_processor
$TotalCores = 0
foreach ($Processor in $Processors) {
    $TotalCores = $TotalCores + $Processor.NumberofCores
}
"Number of cores is $TotalCores"

# Limit number of TempDB Files to 8 maximum
If ($TotalCores -gt 8) {
    $NumberOfTempDBFiles = 8
}
Else {$NumberOfTempDBFiles = $TotalCores}


If ($DefaultInstanceName) {
    "Default Instance Detected"
    $ConnectionString = "$ENV:Computername"
}
Else {
    $ConnectionString = "$ENV:Computername\$InstanceName"
    "Changing Listening port for SQL Service to 1113 for a non-default instance"
    $urn = "ManagedComputer[@Name='$env:COMPUTERNAME']/ServerInstance[@Name='$InstanceName']/ServerProtocol[@Name='Tcp']"
    $SMOWmiserver.GetSmoObject($urn + "/IPAddress[@Name='IPAll']").IPAddressProperties[1].Value = "1113"
    $Tcp = $SMOWmiserver.GetSmoObject($urn)
    $Tcp.alter()
    $Tcp
    "Port change complete. Requires a service restart to take effect"
    $SMOWmiserver.GetSmoObject($urn + "/IPAddress[@Name='IPAll']").IPAddressProperties
}
"Preparing for setting backup location for SQL by defining the SMOServer"
If ($DefaultInstanceName) {
    $svr = new-object ('Microsoft.SqlServer.Management.Smo.Server') localhost
}
else {
    $svr = new-object ('Microsoft.SqlServer.Management.Smo.Server') "localhost\$InstanceName"
}

# This section modifies the folder structure for backups, ifa default instance is used, the backup path should be SQLBackups:\$ServerName, if it is anamed instance, the path should be SQLBackups:\$ServerName\$InstanceName
If ($DefaultInstanceName) {
    $BackupLocation = "$ServerName"
}
Else {
    $BackupLocation = "$ServerName\$InstanceName"
}
"Backup Location will be set to $BackupLocation"

"Creating Backup Directories for $Domain"
<#If ($Domain -eq "kpmgtest.com") {
    "Server in kpmgtest.com so creating Network Backup Directories"
    $DomainCredential = new-object -typename System.Management.Automation.PSCredential -argumentlist $TestDomainAccount, $TestDomainPassword 
    New-PSDrive -Name SQLBackups -PSProvider FileSystem -Root "\\kpmgtest.com\tst\infra\sql-backups" -Credential $DomainCredential
    "Creating FULL directory"
    New-Item -ItemType directory -Path "SQLBackups:\$BackupLocation\FULL"
    "Creating zzScriptPermsAndJobs directory"
    New-Item -ItemType directory -Path "SQLBackups:\$BackupLocation\FULL\zzScriptPermsAndJobs"
    "Creating FULL_RESTORE_TEMP directory"
    New-Item -ItemType directory -Path "SQLBackups:\$BackupLocation\FULL_RESTORE_TEMP" 
    "Creating FULL_PRESERVE directory"
    New-Item -ItemType directory -Path "SQLBackups:\$BackupLocation\FULL_PRESERVE" 
    "Creating CommissioningBackups directory"
    New-Item -ItemType directory -Path "SQLBackups:\$BackupLocation\FULL_PRESERVE\CommissioningBackups" 
    "Creating DIFF directory"
    New-Item -ItemType directory -Path "SQLBackups:\$BackupLocation\DIFF" 
    "Creating TLOG directory"
    New-Item -ItemType directory -Path "SQLBackups:\$BackupLocation\TLOG" 
    "Setting Default Backup Location for Test:"
    set-itemproperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($svr.ServiceInstanceId)\MSSQLServer" -name "BackupDirectory" -value "\\kpmgtest.com\tst\infra\sql-backups\$BackupLocation\FULL" -ErrorAction Stop
}
Elseif ($Domain -eq "kpmgprod.com") {
    "Server in kpmgprod.com so creating Network Backup Directories"
    $DomainCredential = new-object -typename System.Management.Automation.PSCredential -argumentlist $ProdDomainAccount, $ProdDomainPassword 
    New-PSDrive -Name SQLBackups -PSProvider FileSystem -Root "\\kpmgprod.com\prd\infra\sql-backups" -Credential $DomainCredential
    "Creating FULL directory"
    New-Item -ItemType directory -Path "SQLBackups:\$BackupLocation\FULL" 
    "Creating zzScriptPermsAndJobs directory"
    New-Item -ItemType directory -Path "SQLBackups:\$BackupLocation\FULL\zzScriptPermsAndJobs" 
    "Creating FULL_RESTORE_TEMP directory"
    New-Item -ItemType directory -Path "SQLBackups:\$BackupLocation\FULL_RESTORE_TEMP" 
    "Creating FULL_PRESERVE directory"
    New-Item -ItemType directory -Path "SQLBackups:\$BackupLocation\FULL_PRESERVE" 
    "Creating CommissioningBackups directory"
    New-Item -ItemType directory -Path "SQLBackups:\$BackupLocation\FULL_PRESERVE\CommissioningBackups"
    "Creating DIFF directory"
    New-Item -ItemType directory -Path "SQLBackups:\$BackupLocation\DIFF" 
    "Creating TLOG directory"
    New-Item -ItemType directory -Path "SQLBackups:\$BackupLocation\TLOG" 
    "Setting Default Backup Location for Prod:"
    set-itemproperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($svr.ServiceInstanceId)\MSSQLServer" -name "BackupDirectory" -value "\\kpmgprod.com\prd\infra\sql-backups\$BackupLocation\FULL" -ErrorAction Stop

}#>

"Checking if TCP Dynamic Port is set"
If (Test-path -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($svr.ServiceInstanceId)\MSSQLServer\SuperSocketNetLib\Tcp\IPAll") {
    "TCP Dynamic Port is set so disabling this"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($svr.ServiceInstanceId)\MSSQLServer\SuperSocketNetLib\Tcp\IPAll" -Name "TcpDynamicPorts" -Value ""
}
Else {
    "TCP Dynamic Port is not set - no change necessary"
}

"Enabling Named Pipes"
$urn = "ManagedComputer[@Name='$env:COMPUTERNAME']/ServerInstance[@Name='$InstanceName']/ServerProtocol[@Name='Np']"
$Np = $SMOWmiserver.GetSmoObject($urn)
$Np.IsEnabled = $true
$Np.Alter()
$Np
"Finished Enabling Named Pipes"

"Configuring SQL Maximums"
"Setting Memory to $MaximumMemory"
Invoke-Sqlcmd -ServerInstance $ConnectionString -ErrorAction Stop -Query ("EXEC sys.sp_configure N'show advanced options', N'1' RECONFIGURE WITH OVERRIDE")
Invoke-Sqlcmd -ServerInstance $ConnectionString -ErrorAction Stop -Query ("EXEC sys.sp_configure N'max server memory (MB)', N'" + $MaximumMemory + "'")

#Set number of TempDB files (Use 1 per CPU up to a max of 8, set size to TempDB size / # of CPUs + 1)

"Creating new TempDB Files..."

"Getting TempDB File Location..."
$TempDBFilename =  Invoke-Sqlcmd -ErrorAction Stop -ServerInstance $ConnectionString -Query ("select physical_name from sys.master_files where name = 'tempdev'")
$TempDBPath = $TempDBFilename.physical_name.substring(0,($TempDBFilename.physical_name.length-10))

"Calculating Size of TempDB Files, taking into account leaving some room for TempDB Logs"
$TDriveStats = get-WmiObject win32_logicaldisk | where DeviceID -eq "T:"
$TempDBFileSize = [Math]::Floor([decimal]($TDriveStats.Freespace * 0.95 / ($NumberOfTempDBFiles + 1) /1024/1024))

"Using a size of $TempDBFileSize per TempDB File"

for($i=2; $i -le $NumberOfTempDBFiles; $i++) {
    "Creating TempDB file number $i"
    Invoke-Sqlcmd -ServerInstance $ConnectionString -ErrorAction Stop -QueryTimeout 6000 -Query ("ALTER DATABASE tempdb ADD FILE ( NAME = N'tempdev$($i)',FILENAME = N'$($TempDBPath)tempdb$($i).ndf' , SIZE =$($TempDBFileSize)MB , FILEGROWTH = 0)")
}

"Resizing Original TempDB File"
Invoke-Sqlcmd -ServerInstance $ConnectionString -ErrorAction Stop -QueryTimeout 6000 -Query ("ALTER DATABASE tempdb MODIFY FILE ( NAME = N'tempdev', SIZE =$($TempDBFileSize)MB , FILEGROWTH = 0)")

"Setting Degrees of Parallelism to match number of CPUs ($NumberOfTempDBFiles)"
Invoke-Sqlcmd -ServerInstance $ConnectionString -ErrorAction Stop -Query ("EXEC sys.sp_configure N'max degree of parallelism', N'" + $NumberOfTempDBFiles + "'")

"Display SQL Service Names:" 
$SMOWmiserver.Services | select name

"Formatting service accounts to be in NetBIOS format"
$SQLServiceAccountInNetbiosFormat = $SQLServiceAccountName.split("@")[1] + "\" + $SQLServiceAccountName.split("@")[0]
$SQLAgentAccountInNetbiosFormat = $SQLAgentAccountName.split("@")[1] + "\" + $SQLAgentAccountName.split("@")[0]

If ($DefaultInstanceName) {
    $ChangeSQLService=$SMOWmiserver.Services | where {$_.name -eq "MSSQLSERVER"} #check service name
    $ChangeSQLAgentService=$SMOWmiserver.Services | where {$_.name -eq "SQLSERVERAGENT"} 
}
Else {
    $ChangeSQLService=$SMOWmiserver.Services | where {$_.name -eq "MSSQL`$$InstanceName"} #check service name
    $ChangeSQLAgentService=$SMOWmiserver.Services | where {$_.name -eq "SQLAgent`$$InstanceName"}
}

"Changing Service Account Logons"
"DEBUG - Obtained Service names: $($ChangeSQLService.name) and $($ChangeSQLAgentService.name)"
#"DEBUG - Setting to account details: $SQLServiceAccountInNetbiosFormat and $SQLServiceAccountPlainPassword"
#"DEBUG - Setting agent to account details: $SQLAgentAccountInNetbiosFormat and $SQLAgentAccountPlainPassword"

$ChangeSQLService.SetServiceAccount($SQLServiceAccountInNetbiosFormat, $SQLServiceAccountPlainPassword)
$ChangeSQLAgentService.SetServiceAccount($SQLAgentAccountInNetbiosFormat, $SQLAgentAccountPlainPassword)

"Finished changing services"

"Restarting SQL Server and starting SQL Server Agent Service"
If ($DefaultInstanceName) {
    Restart-Service "MSSQLSERVER"
    Start-Service "SQLSERVERAGENT"
}
else {
    Restart-Service "MSSQL`$$InstanceName"
    Start-Service "SQLAgent`$$InstanceName"
}
"SQL Services started"

"############# Phase 2 - Copying and running DBA Scripts for maintenance #############"
"Verbose output from scripts stored in $($localScriptPath)Scriptoutput.log"

$SQLTeamDrivePath = "\\kpmgmgmt.com\man\sql-team"
"Relaxing network credentials setting"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "disabledomaincreds" -Value "0"
"Mapping SQLTeamDrive Drive"
$DriveMappedSuccess = $false
$DriveMapAttempts = 0
while(!$DriveMappedSuccess -and $DriveMapAttempts -lt 10) {
    $DriveMapAttempts++
    "Mapping Drive (attempt $DriveMapAttempts)"
    New-PSDrive -Name SQLTeamDrive -PSProvider FileSystem -Root "$SQLTeamDrivePath" -Credential $Cred
If (Test-Path SQLTeamDrive:\ -PathType Container) {
    $DriveMappedSuccess = $true
}
Else { 
"Drive Mapping Failed, waiting 5 seconds"
    Start-Sleep -s 5
}
} #end while

"Copying scripts locally"
$localScriptPath = "S:\SQLInstallSupport\Scripts"

New-Item -ItemType directory -Path $localScriptPath
$FileCopySuccess = $false
$FileCopyAttempt = 0
while (!$FileCopySuccess -and $FileCopyAttempt -lt 20) {
    try {
        $FileCopyAttempt++  
        "Copying NewBuild Scripts (Attempt $FileCopyAttempt)"  
        Copy-Item SQLTeamDrive:\02_ServerCommissioningScripts\NewBuildScripts\* $localScriptPath -ErrorVariable FileCopyError -ErrorAction Stop
        $FileCopySuccess = $true
    }
    catch {
        "Error copying NewBuild Scripts"
        "Error is: $FileCopyError"
        "Detailed Error exception:"
        $error[0].exception | fl * -for
        $FileCopyError.Clear()
        Start-Sleep -Seconds 5
    }
} #end while
"New Build Scripts Copied Successfully after $FileCopyAttempt attempts"

New-Item -ItemType directory -Path $localScriptPath\PolicyBasedManagement
$FileCopySuccess = $false
$FileCopyAttempt = 0
while (!$FileCopySuccess -and $FileCopyAttempt -lt 20) {
    try {
        $FileCopyAttempt++  
        "Copying PolicyBased Management Scripts (Attempt $FileCopyAttempt)"  
        Copy-Item SQLTeamDrive:\02_ServerCommissioningScripts\PolicyBasedManagement\* "$localScriptPath\PolicyBasedManagement"-ErrorVariable FileCopyError -ErrorAction Stop
        $FileCopySuccess = $true
    }
    catch {
        "Error copying PolicyBased Management Scripts"
        "Error is: $FileCopyError"
        "Detailed Error exception:"
        $error[0].exception | fl * -for
        $FileCopyError.Clear()
        Start-Sleep -Seconds 5
    }
} #end while
"PolicyBased Management Scripts Copied Successfully after $FileCopyAttempt attempts" 

"Running Build Scripts"
$SQLFiles = get-childitem $localScriptPath | Where {$_.Name -match "[0-9]{2}"}
Foreach ($File in $SQLFiles) {
    if ($File -like "*.sql") {
        "################## Running $File ################## " |Out-File "$($localScriptPath)\Scriptoutput.log" -Append
        Invoke-Sqlcmd -ServerInstance $ConnectionString -ErrorAction Stop -InputFile "$localScriptPath\\$File" -verbose *>> "$($localScriptPath)\Scriptoutput.log"
        Write-Output `n |Out-File "$($localScriptPath)\Scriptoutput.log" -Append
    } #end if like *.sql
}

"Running PolicyBasedManagement Scripts"
$SQLFiles = get-childitem $localScriptPath\PolicyBasedManagement
Foreach ($File in $SQLFiles) {
    if ($File -like "*.sql" -and [int]$File.Name.Substring(0,3) -lt 100) {
        "################## Running $File ################## " |Out-File "$($localScriptPath)\Scriptoutput.log" -Append
        Invoke-Sqlcmd -ServerInstance $ConnectionString -ErrorAction Stop -InputFile "$localScriptPath\PolicyBasedManagement\$File" -verbose *>> "$($localScriptPath)\Scriptoutput.log"
    } #end if like *.sql
}

"Output of running scripts:"
Get-Content "$($localScriptPath)\Scriptoutput.log"  |Write-Output

"Add Trace-Flags"
if ($SetSQL2016Flags) {
    "This is a SQL 2016 Server or highger so not including T1117 and T1118 flags"
    $StartupParameters = @('-T1222','-T3226','-T4199')
}
else {
    
    $StartupParameters = @('-T1222','-T1117','-T1118','-T3226','-T4199')

    $hklmRootNode = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server"
    $props = Get-ItemProperty "$hklmRootNode\Instance Names\SQL"
    $instances = $props.psobject.properties | ?{$_.Value -like 'MSSQL*'} | select Value

    $instances | %{
        $inst = $instances.Value;
        $regKey = "$hklmRootNode\$inst\MSSQLServer\Parameters"
        $props = Get-ItemProperty $regKey
        $params = $props.psobject.properties | ?{$_.Name -like 'SQLArg*'} | select Name, Value
	
        foreach ($StartupParameter in $StartupParameters) {
            $hasFlag = $false

            foreach ($param in $params) {
                if ($param.Value -eq $StartupParameter) {
                    "$StartupParameter already added"
                    $hasFlag = $true
                    break
                 } #end if
            } #end foreach

            if ($hasFlag -eq $false) {
                "Add $StartupParameter"
                $props = Get-ItemProperty $regKey
                $params = $props.psobject.properties | ?{$_.Name -like 'SQLArg*'}
                $newRegProp = "SQLArg"+($params.Count)
                Set-ItemProperty -Path $regKey -Name $newRegProp -Value $StartupParameter
            } #end if
        } #end foreach
    } # end instances
} # end if SetSQL2016Flags


"############# END Phase 2 #############"

"Backing Up Service Master Key"
# IMPORTANT: The service master key must be created and backed up only when the service accounts have been changed

#Invoke-Sqlcmd -ServerInstance $ConnectionString -Query ("BACKUP SERVICE MASTER KEY TO FILE = 'S:\SQLInstallSupport\$ServerName_$InstanceName.bak' ENCRYPTION BY PASSWORD = '$BackupPlainPassword'")

Invoke-Sqlcmd -ServerInstance $ConnectionString -ErrorAction Stop -Query ("USE MASTER `
                                                        GO `
                                                        CREATE MASTER KEY ENCRYPTION BY PASSWORD = '$BackupPlainPassword';")
Invoke-Sqlcmd -ServerInstance $ConnectionString -ErrorAction Stop -Query ("USE MASTER `
                                                        GO `
                                                        BACKUP MASTER KEY TO FILE = 'S:\SQLInstallSupport\$ServerName_$InstanceName.bak' `
                                                        ENCRYPTION BY PASSWORD = '$BackupPlainPassword';")

"Copying Master Key to Network Share"

Copy-Item "S:\SQLInstallSupport\$ServerName_$InstanceName.bak" SQLTeamDrive:\01_Servers\KPC\$NetBiosDomainName\$ServerName\$InstanceName\Keys\ -ErrorAction Stop
"Deleting local Master Key File"
Remove-Item  "S:\SQLInstallSupport\$ServerName_$InstanceName.bak"

"Backing Up Certificate"
$BackupCertificateFileName = "$($ServerName)_$($InstanceName)_BackupCertificate"

Invoke-Sqlcmd -ServerInstance $ConnectionString -ErrorAction Stop -Query ("USE MASTER `
                                                        GO `
                                                        CREATE CERTIFICATE BackupCertificate `
                                                        WITH SUBJECT = 'SQL Server Backup Certificate';")
Invoke-Sqlcmd -ServerInstance $ConnectionString -ErrorAction Stop -Query ("BACKUP CERTIFICATE BackupCertificate `
                                                        TO FILE = 'S:\SQLInstallSupport\$($BackupCertificateFileName).cer' `
                                                        WITH PRIVATE KEY `
                                                        (FILE = 'S:\SQLInstallSupport\$($BackupCertificateFileName).PVK', `
                                                        ENCRYPTION BY PASSWORD = '$BackupPlainPassword')")
"Copying Backup Certificate to Network Share"
Copy-Item "S:\SQLInstallSupport\$($BackupCertificateFileName).cer" SQLTeamDrive:\01_Servers\KPC\$NetBiosDomainName\$ServerName\$InstanceName\Keys\ -ErrorAction Stop
"Deleting local Backup Certificate File"
Remove-Item  "S:\SQLInstallSupport\$($BackupCertificateFileName).cer"

"Copying Backup Certificate Private Key to Network Share"
Copy-Item "S:\SQLInstallSupport\$($BackupCertificateFileName).PVK" SQLTeamDrive:\01_Servers\KPC\$NetBiosDomainName\$ServerName\$InstanceName\Keys\ -ErrorAction Stop
"Deleting local Backup Certificate Private Key File"
Remove-Item  "S:\SQLInstallSupport\$($BackupCertificateFileName).PVK"
       
"Configuring Local Security Policy to add service accounts to Perform Volume Maintenance Tasks"
$sidstr = $null

try {
       $ntprincipal = new-object System.Security.Principal.NTAccount "$SQLServiceAccountName"
       $sid = $ntprincipal.Translate([System.Security.Principal.SecurityIdentifier])
       $sidstr = $sid.Value.ToString()
} catch {
       $sidstr = $null
}
"Account: $($SQLServiceAccountName)"
if( [string]::IsNullOrEmpty($sidstr) ) {
       "Account not found!"
}

"Account SID: $($sidstr)"
$tmp = ""
$tmp = [System.IO.Path]::GetTempFileName()
"Export current Local Security Policy"
secedit.exe /export /cfg "$($tmp)" 
$c = ""
$c = Get-Content -Path $tmp
$currentSetting = ""
foreach($s in $c) {
       if( $s -like "SeManageVolumePrivilege*") {
             $x = $s.split("=",[System.StringSplitOptions]::RemoveEmptyEntries)
             $currentSetting = $x[1].Trim()
       }
}


if( $currentSetting -notlike "*$($sidstr)*" ) {
       "Modify Setting ""Perform Volume Maintenance Task"""
       
       if( [string]::IsNullOrEmpty($currentSetting) ) {
             $currentSetting = "*$($sidstr)"
       } else {
             $currentSetting = "*$($sidstr),$($currentSetting)"
       }
       
       Write-Host "$currentSetting"
       
       $outfile = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
SeManageVolumePrivilege = $($currentSetting)
"@
       
       $tmp2 = ""
       $tmp2 = [System.IO.Path]::GetTempFileName()
         
       "Import new settings to Local Security Policy" 
       $outfile | Set-Content -Path $tmp2 -Encoding Unicode -Force
       #notepad.exe $tmp2
       Push-Location (Split-Path $tmp2)
       
       try {
             secedit.exe /configure /db "secedit.sdb" /cfg "$($tmp2)" /areas USER_RIGHTS 
             #write-host "secedit.exe /configure /db ""secedit.sdb"" /cfg ""$($tmp2)"" /areas USER_RIGHTS "
       } finally {  
             Pop-Location
       }
} else {
       "NO ACTIONS REQUIRED! Account already in ""Perform Volume Maintenance Task"""
}
Write-Host "Security Policy Update Complete."

"Setting SQL Agent Values:"
"--Replace tokens for all job responses--"
Invoke-Sqlcmd -ServerInstance $ConnectionString -ErrorAction Stop -Query ("USE MSDB `
    GO `
    EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1, `
		@alert_replace_runtime_tokens=1, `
		@use_databasemail=1;")


"Rename SA account"
Invoke-Sqlcmd -ServerInstance $ConnectionString -ErrorAction Stop -Query ("ALTER LOGIN sa WITH NAME = [SystemAdministrator]")
"SA Login Renamed"

"Disable SystemAdministrator account"
Invoke-Sqlcmd -ServerInstance $ConnectionString -ErrorAction Stop -Query ("ALTER LOGIN [SystemAdministrator] DISABLE") 
"SystemAdministrator account disabled"

############ Ensure this is the last SQL Step #####################
#"Disable darwin login in SQL"
#Invoke-Sqlcmd -ServerInstance $ConnectionString -ErrorAction Stop -Query ("ALTER LOGIN [$Env:Computername\darwin] DISABLE")
#"Darwin SQL account disabled"
###################################################################
"Restart the SQL Server service"
If ($DefaultInstanceName) {
    Restart-Service "MSSQLSERVER" -Force
}
Else {
    Restart-Service "MSSQL`$$InstanceName" -Force
}

"Finishing main try section."
"Contents of error: $error"
"Clearing errors:"
$error.clear()
} # End try


Catch {
    "Catch - Error Installing SQL Server - Guest script"
    $errorcount = $error.count
    "Error Count: $errorcount"
    "Contents of error: $error"
    $error[0].exception | fl * -for
    if ($DebugOn) {
        #Start-Sleep -s 6000
    }
    exit 666
} #end catch

finally {
    "FINALLY - Performing cleanup tasks"
    Set-Location c:
    Foreach ($Drive in $Drives) {
        $DriveName = $Drive.Name
        If ($DriveName.Length -gt 1) {
            "Removing PSDrive $DriveName"
            Remove-PSDrive -Name $DriveName
        } #end if
    } # end for each
    "Deleting any mapped drives to prevent issue with downstream installs"
    net use
    net use * /d /y
    "Outputting Content of SQL Install Log if it exists"
    if (test-path "S:\SQLInstallSupport\Summary*") {
        $SQLLogContent = Get-Content "S:\SQLInstallSupport\Summary*"
        $SQLLogContent
    "Resetting network credentials setting"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "disabledomaincreds" -Value "1"
    $Error.Clear()
    if ($DebugOn) {
        Stop-Transcript
    } #end if
    }
} #end finally