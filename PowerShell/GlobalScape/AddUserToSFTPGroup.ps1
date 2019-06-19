######################################################################################
#
# Author : Yattong Wu
# Date : 10 April 2018
# Version : 1.0
# Purpose : Adding Users to Permissions Groups
# Parameters ; Server, Port, Username, Password, AppID, Project Name, Permission, User
#
######################################################################################

param (
    [string]$serverName,
    [string]$serverPort,
    [string]$adminUserName,
    [string]$adminUserPassword,
    [string]$appID,
    [string]$projectName,
    [string]$permission,     # Download or Upload
    [string]$user
)

# Set all SFTP variables
$domain = "kpmgtest.com"

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
    
    <#Write-Host "User Database Refresh..."
    $site.ForceSynchronizeUserDatabase()
    Write-Host "Waiting for User Database Refresh..."
    sleep 15
    #>

    # Check Whether User Exists, if not force AD replication
    $gsUserExists = $false
    $counter = 0
    Do {
        Write-Host "Attempt ($($counter)) to Find User in GlobalScape"
        $gsUsers = $site.GetUsers()
        foreach ($gsUser in $gsUsers){
            if ($gsUser -eq $user){
                $gsUserExists = $true
                break
            } else {
                $gsUserExists = $false
            }

        }
        
        <#
        if (!$gsUserExists){
        $dcs = Get-ADDomainController -Filter {Domain -eq $domain} -Server $domain
            foreach ($dc in $dcs){
                repadmin /syncall /A $dcs.name
            }
        sleep 15
        Write-Host "User Database Refresh..."
        $site.ForceSynchronizeUserDatabase()
        }
        #>
        $counter++
        
    } while (!$gsUserExists -and $counter -le 5)

    if ($gsUserExists){
        Write-Host -ForegroundColor Red "User $($user) found in GlobalScape"
        # Add user to Permissions Group
        Write-Host "adding $($user) to $($appID)-$($projectName)-$($permission) permissions group"
        $site.AddUserToPermissionGroup($user,"$($appID)-$($projectName)-$($permission)")
    } else {
        Write-Host -ForegroundColor Red "User could not be found in GlobalScape"
    }

} catch {
    $Error
} finally {

    # Close Serve Connection
    Write-Host "Closing Session to SFTP Server"
    $SFTPServer.Close()

}