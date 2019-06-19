#####################################################################
#
# Author : Yattong Wu
# Date : 10 April 2018
# Version : 1.0
# Purpose : Creates KPC SFTP Site
# Parameters ; Server, Port, Username, Password, AppID, Project Name
#
#####################################################################

param (
    [string]$serverName,
    [string]$serverPort,
    [string]$adminUserName,
    [string]$adminUserPassword,
    [string]$appID,
    [string]$projectName
)

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

    # Set all SFTP variables
    $appIDFolder = "SFTP-KPC-TEST/" + $appID.ToUpper()
    $projectNameFolder = $appIDFolder + "/" + $projectName
    $projectInFolder = $projectNameFolder + "/Inbound"
    $projectOutFolder = $projectNameFolder + "/Outbound"
    $projectInboundGroup = $appID.ToUpper() + "-" + $projectName + "-Inbound"
    $projectOutboundGroup = $appID.ToUpper() + "-" + $projectName + "-Outbound"
    $eventRulesFolderName = "$($appID)-$($projectName)"
    $eventRuleName = "$($eventRulesFolderName)-Standard-15Min-Move"
    $localPath = "\\kpmgtest.com\tst\infra\globalscape\eft\$($appID)\$($projectName)\Inbound\*.*"
    $remotePath = "\\kpmgtest.com\tst\$($appID)\$($projectName)\Inbound\*.*"


    ## Check if APPID folder exists
    $rootFolders = $site.GetFolderList("SFTP-KPC-TEST")
    $appIDExists = $false
    foreach ($rootFolder in $rootFolders){
        if ($rootFolder -match $appID){
            $appIDExists = $true
            break
        } else {
            $appIDExists = $false
        }
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

    ## Create Project folders and Permission Groups
    if ($projectExists){
        Write-Host $projectName " Project exist, Nothing can be created"
    } else {
        Write-Host $projectName " Project does not exist, creating SFTP Project Items..."

        ## Create GlobalScape VFS Folders
        # Create Project Folder
        Write-Host "creating folder : $($projectNameFolder)..."
        $folder = $site.CreatePhysicalFolder($projectNameFolder)
        
        # Check if Folder is created
        $folders = $site.GetFolderList($projectNameFolder)
        foreach ($folder in $folders){
            if ($folder -match $projectName){
                $folderCreated = $true
                break
            } else {
                $folderCreated = $false
            }
        }
        if ($folderCreated){
            Write-Host -ForegroundColor Green "creating folder : $($projectNameFolder) successful"
        } else {
            Write-Host -ForegroundColor Red "creating folder : $($projectNameFolder) Failed"
        }

        Write-Host "creating folder : $($projectInFolder)..."
        $folder = $site.CreatePhysicalFolder($projectInFolder)
        Write-Host "creating folder : $($projectOutFolder)..."
        $site.CreatePhysicalFolder($projectOutFolder)

        #Create GlobalScape Permissions Group
        Write-Host "creating Permission Group : $($projectInboundGroup)..."
        $site.CreatePermissionGroup($projectInboundGroup)
        Write-Host "creating Permission Group : $($projectOutboundGroup)..."
        $site.CreatePermissionGroup($projectOutboundGroup)

        # AppID Folder - Remove Administrative and Guests from Permissions and applies User group permissions
        Write-Host "Setting Permissions [Directory Listing] and [Listing in Parent Directory] for $($projectInboundGroup) on : $($appIDFolder)..."
        Write-Host "Setting Permissions on : $($appIDFolder)..."
        $perm = $site.GetBlankPermission($appIDFolder,$projectInboundGroup)
        $perm.DirList = $true
        $perm.DirShowInList = $true
        $site.SetPermission($perm,!$appIDExists)  # set to true if Appid Folder is just created

        # Project Folder - Remove Administrative and Guests from Permissions and applies User group permissions
        Write-Host "Setting Permissions [Directory Listing] and [Listing in Parent Directory] for $($projectInboundGroup) on : $($projectNameFolder)..."
        $perm = $site.GetBlankPermission($projectNameFolder,$projectInboundGroup)
        $perm.DirList = $true
        $perm.DirShowInList = $true
        $site.SetPermission($perm,$true)

        # Inbound Folder - Remove Administrative and Guests from Permissions and applies User group permissions
        Write-Host "Setting Permissions [Directory Listing], [Listing in Parent Directory], [Append] and [Upload] for $($projectInboundGroup) on : $($projectInFolder)..."
        Write-Host "Setting Permissions on : $($projectInFolder)..."
        $perm = $site.GetBlankPermission($projectInFolder,$projectInboundGroup)
        $perm.FileUpload = $true
        $perm.FileAppend = $true
        $perm.DirList = $true
        $perm.DirShowInList = $true
        $site.SetPermission($perm,$true)

        # AppID Folder - Remove Administrative and Guests from Permissions and applies User group permissions
        Write-Host "Setting Permissions [Directory Listing] and [Listing in Parent Directory] for $($projectOutboundGroup) on : $($appIDFolder)..."
        $perm = $site.GetBlankPermission($appIDFolder,$projectOutboundGroup)
        $perm.DirList = $true
        $perm.DirShowInList = $true
        $site.SetPermission($perm,$false)

        # Outbound Folder - Remove Administrative and Guests from Permissions and applies User group permissions
        Write-Host "Setting Permissions [Directory Listing] and [Listing in Parent Directory] for $($projectOutboundGroup) on : $($projectNameFolder)..."
        $perm = $site.GetBlankPermission($projectNameFolder,$projectOutboundGroup)
        $perm.DirList = $true
        $perm.DirShowInList = $true
        $site.SetPermission($perm,$false)

        #Remove Administrative and Guests from Permissions and applies User group permissions
        Write-Host "Setting Permissions [Directory Listing], [Listing in Parent Directory] and [Download] for $($projectOutboundGroup) on : $($projectOutFolder)..."
        $perm = $site.GetBlankPermission($projectOutFolder,$projectOutboundGroup)
        $perm.FileDownload = $true
        $perm.DirList = $true
        $perm.DirShowInList = $true
        $site.SetPermission($perm,$true)

        #Disable Inheritance and remove Admin & Guests
        if (!$appIDExists){
            Write-Host "Disable inheritance on : $($appIDFolder) and remove inherited user permissions..."
            $site.DisableInheritPermissions($appIDFolder,$true)
        }
        Write-Host "Disable inheritance on : $($projectNameFolder) and remove inherited user permissions..."
        $site.DisableInheritPermissions($projectNameFolder,$true)
        Write-Host "Disable inheritance on : $($projectInFolder) and remove inherited user permissions..."
        $site.DisableInheritPermissions($projectInFolder,$true)
        Write-Host "Disable inheritance on : $($projectOutFolder) and remove inherited user permissions..."
        $site.DisableInheritPermissions($projectOutFolder,$true)

        # Create standard 15min move event rule
        Write-Host "Creating Event Rule"
        $rule = $site.EventRules(4097)   #4097 means timer based rule

        # set Event Rule reccurance
        Write-Host "Creating Event Rule Timing Parameters"
        $eventParams = New-Object -ComObject "SFTPCOMInterface.CITimerEventRuleParams"
        $eventParams.Name = $eventRuleName
        $eventParams.Enabled = $true
        $eventParams.Description = "Standard file move every 15 minutes"
        $eventParams.DateTimeStart = Get-Date
        $eventParams.Recurrence = 0
        $eventParams.RepeatEnabled = $true
        $eventParams.RepeatPattern = 1
        $eventParams.RepeatRate = 15

        # Commit Rule
        Write-Host "Committing Event Rule Timing Parameters"
        $eventRule = $rule.Add($rule.Count(), $eventParams)

        # Set action for rule
        Write-Host "Creating Event Rule Action Parameters"
        $actionParams = New-Object -ComObject "SFTPCOMInterface.CIUploadActionParams"
        $actionParams.LocalPath = $localPath
        $actionParams.RemotePath = $remotePath
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

    }

} catch {
    $Error
} finally {

    # Close Serve Connection
    Write-Host "Closing Session to SFTP Server"
    $SFTPServer.Close()

}