#################################################################################
#
# Author : Yattong Wu
# Date : 10 April 2018
# Version : 1.0
# Purpose : Creates KPC SFTP Site
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
$projectNameFolder = $appIDFolder + "/" + $projectName
$projectOutFolder = $projectNameFolder + "/Outbound"
$projectOutboundGroup = $appID.ToUpper() + "-" + $projectName + "-Outbound"


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

    ## Create Project Folder
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
    # Create Project Outbound Folder
    Write-Host "Creating  Outbound folder : $($projectOutFolder)..."
    $folder = $site.CreateVirtualFolder($projectOutFolder, $remotePath)
        
    ###### Create Permissions Groups #######   

    #Create GlobalScape Permissions Group
    Write-Host "creating Permission Group : $($projectOutboundGroup)..."
    $site.CreatePermissionGroup($projectOutboundGroup)

    ###### Apply Permissions Groups to Folder #######   

    # AppID Folder - Get Permissions API Template and applies User group permissions
    Write-Host "Setting Permissions [Directory Listing] and [Listing in Parent Directory] for $($projectOutboundGroup) on : $($appIDFolder)..."
    $perm = $site.GetBlankPermission($appIDFolder,$projectOutboundGroup)
    $perm.DirList = $true
    $perm.DirShowInList = $true
    $site.SetPermission($perm,!$appIDExists)

    # Project Folder - Get Permissions API Template and applies User group permissions
    Write-Host "Setting Permissions [Directory Listing] and [Listing in Parent Directory] for $($projectOutboundGroup) on : $($projectNameFolder)..."
    $perm = $site.GetBlankPermission($projectNameFolder,$projectOutboundGroup)
    $perm.DirList = $true
    $perm.DirShowInList = $true
    $site.SetPermission($perm,!$projectExists)

    # Outbound Folder - Get Permissions API Template and applies User group permissions
    Write-Host "Setting Permissions [Directory Listing], [Listing in Parent Directory] and [Download] for $($projectOutboundGroup) on : $($projectOutFolder)..."
    $perm = $site.GetBlankPermission($projectOutFolder,$projectOutboundGroup)
    $perm.FileDownload = $true
    $perm.DirList = $true
    $perm.DirShowInList = $true
    $site.SetPermission($perm,$true)

    #Disable Inheritance and remove Admin & Guests
    #Disable Inheritance and remove Admin & Guests
    if (!$appIDExists){
        Write-Host "Disable inheritance on : $($appIDFolder) and remove inherited user permissions..."
        $site.DisableInheritPermissions($appIDFolder,$true)
    }
    if (!$projectExists){
        Write-Host "Disable inheritance on : $($projectNameFolder) and remove inherited user permissions..."
        $site.DisableInheritPermissions($projectNameFolder,$true)
    }
    Write-Host "Disable inheritance on : $($projectOutFolder) and remove inherited user permissions..."
    $site.DisableInheritPermissions($projectOutFolder,$true)


} catch {
    $Error
} finally {

    # Close Serve Connection
    Write-Host "Closing Session to SFTP Server"
    $SFTPServer.Close()

}