#################################################################################
#
# Author : Yattong Wu
# Date : 10 April 2018
# Version : 1.0
# Purpose : Creates KPC SFTP Inbound
# Parameters ; Server, Port, Username, Password, AppID, Project Name, RemotePath
#
##################################################################################

param (
    [string]$serverName,
    [string]$serverPort,
    [string]$adminUserName,
    [string]$adminUserPassword,
    [string]$appID,
    [string]$projectName,
    [string]$remotePath
)

# Set all SFTP variables
$rootFolderName = "KPC-SFTP"
$appIDFolder = $rootFolderName + "/" + $appID.ToUpper()
if ($projectName){
    $projectNameFolder = $appIDFolder + "/" + $projectName
    $projectInFolder = $projectNameFolder + "/Inbound"
    $projectInboundGroup = $appID.ToUpper() + "-" + $projectName + "-Inbound"
    $eventRuleName = "$($eventRulesFolderName)-Move-On-Logoff"
    $vfsCachePath = "\\kpmgtest.com\tst\infra\globalscape\eft\SFTP-Cache\$($appID)\$($projectName)\Inbound"
} else {
    $projectInFolder = $appIDFolder + "/Inbound"
    $projectInboundGroup = $appID.ToUpper() + "-" + "-Inbound"
    $eventRuleName = "$($eventRulesFolderName)-Move-On-Logoff"
    $vfsCachePath = "\\kpmgtest.com\tst\infra\globalscape\eft\SFTP-Cache\$($appID)\Inbound"
}


#### CIFS Execution ####

# Test Cache path exist
Write-Host -ForegroundColor Cyan "Searching for Directory $($vfsCachePath)..."
if (Test-Path $vfsCachePath){
    Write-Host -ForegroundColor Cyan "Directory $($vfsCachePath) exists"

} else {
    Write-Host -ForegroundColor Cyan "Directory $($vfsCachePath) does not exist, creating SFTP Cache Directory"
    New-Item -Path $vfsCachePath -ItemType directory
}


#### GlobalScape Execution #####

try {
    # Instantiate COM Object
    Write-Host -ForegroundColor Cyan "Initializing SFTP COM API Object..."
    $SFTPServer = New-Object -ComObject "SFTPCOMInterface.CIServer"
    if ($SFTPServer){
        Write-Host -ForegroundColor Green "SFTP COM API Object Initialized"
    } else {
        Write-Host -ForegroundColor Red "SFTP COM API Object Failed to Initialize"
    }

    # Connect to SFTP Server
    Write-Host -ForegroundColor Cyan "Connecting to SFTP Server $($serverName) on $($serverPort)..."
    $SFTPServer.Connect($serverName, $serverPort, $adminUserName, $adminUserPassword)

    # Variablise Site
    $sites = $SFTPServer.Sites()
    if ($SFTPServer){
        Write-Host -ForegroundColor Green "SFTP Server $($serverName) on $($serverPort) Connection Successful"
    } else {
        Write-Host -ForegroundColor Red "SFTP Server $($serverName) on $($serverPort) Connection Failed"
    }
    $site = $sites.Item(0)

    # Refresh Server
    Write-Host "Server Refresh..."
    $SFTPServer.RefreshSettings()

    
    ## Check if APPID folder exists
    $rootFolders = $site.GetFolderList($rootFolderName)
    $appIDExists = $false
    foreach ($rootFolder in $rootFolders){
        if ($rootFolder -match $appID){
            $appIDExists = $true
            break
        } else {
            $appIDExists = $false
        }
    }


    ## Create App ID Folder
    if ($appIDExists){
        Write-Host $appID " folder already exists.. moving onto creating project folders..."
    } else {
        Write-Host $appID " folder does not exist, creating APPID folder..."
        $site.CreatePhysicalFolder($appIDFolder)

        # Create Event Rule Folder
        Write-Host "Creating Event Rules Folder"
        $eventRuleFolders = $site.EventRuleFolders()
        $eventRuleFolders.Add(0,$appIDFolder)
    }


    ## Check if Project Folder exists
    $projectFolders = $site.GetFolderList($appIDFolder)
    foreach ($projectFolder in $projectFolders){
        if ($projectFolder -match $projectName){
            $projectExists = $true
            break
        } else {
            $projectExists = $false
        }
    }


    ## Create Project Folder and Permission Groups
    if ($projectExists){
        Write-Host $projectName " Project exist, no need to create Project"
    } else {
        Write-Host $projectName " Project does not exist, creating SFTP Project Items..."

        # Create GlobalScape VFS Folders
        # Create Project Folder
        Write-Host "creating folder : $($projectNameFolder)..."
        $folder = $site.CreatePhysicalFolder($projectNameFolder)
    }


    # Create GlobalScape VFS Folders
    # Create Project Inbound Folder
    Write-Host "creating folder : $($projectInFolder)..."
    $folder = $site.CreateVirtualFolder($projectInFolder, $vfsCachePath)


    ###### Create Permissions Groups #######   
        
    #Create Inbound Permissions Group
    Write-Host "creating Permission Group : $($projectInboundGroup)..."
    $site.CreatePermissionGroup($projectInboundGroup)
    
    ###### Apply Permissions Groups to Folders #######   
        
    # AppID Folder - Get Permissions API Template and applies User group permissions
    Write-Host "Setting Permissions [Directory Listing] and [Listing in Parent Directory] for $($projectInboundGroup) on : $($appIDFolder)..."
    Write-Host "Setting Permissions on : $($appIDFolder)..."
    $perm = $site.GetBlankPermission($appIDFolder,$projectInboundGroup)
    $perm.DirList = $true
    $perm.DirShowInList = $true
    $site.SetPermission($perm,!$appIDExists)  # set to true if Appid Folder is just created

    # Project Folder - Get Permissions API Template and applies User group permissions
    Write-Host "Setting Permissions [Directory Listing] and [Listing in Parent Directory] for $($projectInboundGroup) on : $($projectNameFolder)..."
    $perm = $site.GetBlankPermission($projectNameFolder,$projectInboundGroup)
    $perm.DirList = $true
    $perm.DirShowInList = $true
    $site.SetPermission($perm,!$projectExists)

    # Inbound Folder - Get Permissions API Template and applies User group permissions
    Write-Host "Setting Permissions [Directory Listing], [Listing in Parent Directory], [Append] and [Upload] for $($projectInboundGroup) on : $($projectInFolder)..."
    Write-Host "Setting Permissions on : $($projectInFolder)..."
    $perm = $site.GetBlankPermission($projectInFolder,$projectInboundGroup)
    $perm.FileUpload = $true
    $perm.FileAppend = $true
    $perm.DirList = $true
    $perm.DirShowInList = $true
    $site.SetPermission($perm,$true)

    #Disable Inheritance and remove Admin & Guests
    if (!$appIDExists){
        Write-Host "Disable inheritance on : $($appIDFolder) and remove inherited user permissions..."
        $site.DisableInheritPermissions($appIDFolder,$true)
    }
    if (!$projectExists){
        Write-Host "Disable inheritance on : $($projectNameFolder) and remove inherited user permissions..."
        $site.DisableInheritPermissions($projectNameFolder,$true)
    }
    Write-Host "Disable inheritance on : $($projectInFolder) and remove inherited user permissions..."
    $site.DisableInheritPermissions($projectInFolder,$true)
        

    ###### Create Rules #######   

    ## Check if EventRule Folder Exists
    Write-Host "Checking if Event Rule Folder Exists"
    $eventRuleFolders = $site.EventRuleFolders()
    for ($i = 0; $i -lt $eventRuleFolders.count(); $i++){
        if ($eventRuleFolders.Item($i).Name -eq $appID){
            $eventFolderExists = $true
            break
        } else {
            $eventFolderExists = $false
        }
    }

    ## create EventRule Folder
    if ($eventFolderExists){
        Write-Host "Event Rule Folder already exists"
    } else {
        Write-Host "Creating Event Rule Folder"
        $eventRuleFolder = $site.EventRuleFolders()
        $eventRuleFolder.Add(0, $appID)
    }


    ## Create Logout Rule
    # Create standard 15min move event rule
    Write-Host "Creating Event Rule"
    $rule = $site.EventRules(16387)   #4097 means timer based rule, 16387 is client logged out

    # set Event Rule reccurance
    Write-Host "Creating Event Rule Log Out Parameters"
    $eventParams = New-Object -ComObject "SFTPCOMInterface.CIEventRuleParams"
    $eventParams.Name = $eventRuleName
    $eventParams.Enabled = $true
    $eventParams.Description = "Standard file move every on log out"

    # Commit Rule
    Write-Host "Committing Log Out Rule Parameters"
    $eventRule = $rule.Add($rule.Count(), $eventParams)

    # Set Condition
    #$eventRule.AddIfStatement(0, "Client", "MemberOf", $projectInboundGroup)

    # Set action for rule
    Write-Host "Creating Event Rule Action Parameters"
    $actionParams = New-Object -ComObject "SFTPCOMInterface.CIUploadActionParams"
    $actionParams.LocalPath = "$($vfsCachePath)\*.*"
    $actionParams.RemotePath = "$($remotePath)\*.*"
    $actionParams.DeleteSourceFile = $true
    $actionParams.Protocol = -1                          # -1 equals Local
    $actionParams.OverwriteType = 3                      # 3 equals numerate

    # Commit Action to Rule
    Write-Host "Committing Event Rule Action Parameters"
    $eventRule.AddActionStatement($eventRule.StatementsCount(), $actionParams)

    # Add Event Rule to Event Rule Folder
    # Refresh Server
    $SFTPServer.RefreshSettings()
    sleep 15
    Write-Host "Moving Rule to App ID Folder"
    $eventRuleFolder = $site.EventRuleFolders().Find($appID)
    $eventRuleFolder.Add(0,$eventRuleName)


} catch {
    $Error
} finally {

    # Close Serve Connection
    Write-Host "Closing Session to SFTP Server"
    $SFTPServer.Close()

}