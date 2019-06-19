#####################################################################
#
# Author : Yattong Wu
# Date : 10 April 2018
# Version : 1.0
# Purpose : Removes KPC SFTP Site
# Parameters ; Server, Port, Username, Password, AppID, Project Name
#
#####################################################################

# Initialize Parameters
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


    ## Remove Project folders and Permission Groups
    if ($projectExists){
        Write-Host $projectName " Project exist, Starting to remove..."
    
        # Remove GlobalScape VFS Folders
        Write-Host "Removing folder : $($projectNameFolder)..."
        $site.RemoveFolder($projectNameFolder)

        # Remove GlobalScape Permissions Group
        Write-Host "Removing Permission Group : $($projectInboundGroup)..."
        $site.RemovePermissionGroup($projectInboundGroup)
        Write-Host "Removing Permission Group : $($projectOutboundGroup)..."
        $site.RemovePermissionGroup($projectOutboundGroup)


        # Remove standard 15min move event rule
        Write-Host "Removing Event Rule"
        $rules = $site.EventRules(4097)
        for ($i = 0; $i -lt $rules.Count(); $i++){
            $rule = $rules.Item($i)
            $ruleParams = $rule.GetParams()
            if ($ruleParams.Name -match $eventRuleName){
               $rules.Delete($i)
               break
            }
        }
    } else {
        Write-Host $projectName " Project does not exist, cannot remove"
    }

} catch {
    $Error
} finally {

    # Close Serve Connection
    Write-Host "Closing Session to SFTP Server"
    $SFTPServer.Close()

}