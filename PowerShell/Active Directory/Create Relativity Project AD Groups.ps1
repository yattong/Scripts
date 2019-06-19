# Create KPC Standard Project Groups for Relativity
$projectName = Read-Host "Project Name"
$appID = "BRA01P"
$createDataRoom = Read-Host "Create Dataroom Y/N?"

switch ($appID.Substring(5,1) ){
    P {
        $domain = "kpmgprod.com"
        $shortDomainName = "PRD"
        $userGroupLocation = "OU=UserGroups,OU=SecurityGroups,OU=KPMGC2,DC=kpmgprod,DC=com"
        $resourceGroupLocation = "OU=ResourceGroups,OU=SecurityGroups,OU=KPMGC2,DC=kpmgprod,DC=com"
       }
    U {
        $domain = "kpmgprod.com"
        $shortDomainName = "UAT"
        $userGroupLocation = "OU=UserGroups,OU=SecurityGroups,OU=KPMGC2_UAT,DC=kpmgprod,DC=com"
        $resourceGroupLocation = "OU=ResourceGroups,OU=SecurityGroups,OU=KPMGC2_UAT,DC=kpmgprod,DC=com"
       }
    T {
        $domain = "kpmgtest.com"
        $shortDomainName = "TST"
        $userGroupLocation = "OU=UserGroups,OU=SecurityGroups,OU=KPMGC2,DC=kpmgtest,DC=com"
        $resourceGroupLocation = "OU=ResourceGroups,OU=SecurityGroups,OU=KPMGC2,DC=kpmgtest,DC=com"
        }
    D {
        $domain = "kpmgtest.com"
        $shortDomainName = "DEV"
        $userGroupLocation = "OU=UserGroups,OU=SecurityGroups,OU=KPMGC2_DEV,DC=kpmgtest,DC=com"
        $resourceGroupLocation = "OU=ResourceGroups,OU=SecurityGroups,OU=KPMGC2_DEV,DC=kpmgtest,DC=com"
      }
}

try {
    Write-Host -ForegroundColor Cyan "Creating Standard Groups"
    $adminUserGroup = New-ADGroup -GroupScope Global -GroupCategory Security -Name "ACC$($shortDomainName)_EDM_$($appID)_$($projectName)_Admins" -Description "$($appID) $($projectName) Admins" -Path $userGroupLocation -Server $domain -PassThru
    $allowCopyPasteUserGroup = New-ADGroup -GroupScope Global -GroupCategory Security -Name "ACC$($shortDomainName)_EDM_$($appID)_$($projectName)_AllowCopyPaste" -Description "$($appID) $($projectName) AllowCopyPaste" -Path $userGroupLocation -Server $domain -PassThru
    $allowMapDriveUserGroup = New-ADGroup -GroupScope Global -GroupCategory Security -Name "ACC$($shortDomainName)_EDM_$($appID)_$($projectName)_AllowLocalDriveMap" -Description "$($appID) $($projectName) AllowLocalDriveMap" -Path $userGroupLocation -Server $domain -PassThru
    $allowPrintUserGroup = New-ADGroup -GroupScope Global -GroupCategory Security -Name "ACC$($shortDomainName)_EDM_$($appID)_$($projectName)_AllowPrint" -Description "$($appID) $($projectName) AllowPrint" -Path $userGroupLocation -Server $domain -PassThru
    New-ADGroup -GroupScope Global -GroupCategory Security -Name "ACC$($shortDomainName)_EDM_$($appID)_$($projectName)_Approvers" -Description "$($appID) $($projectName) Approvers" -Path $userGroupLocation -Server $domain -PassThru
    $projectUserGroup = New-ADGroup -GroupScope Global -GroupCategory Security -Name "ACC$($shortDomainName)_EDM_$($appID)_$($projectName)_Project" -Description "$($appID) $($projectName) Project" -Path $userGroupLocation -Server $domain -PassThru
    $roUserGroup = New-ADGroup -GroupScope Global -GroupCategory Security -Name "ACC$($shortDomainName)_EDM_$($appID)_$($projectName)_RO" -Description "$($appID) $($projectName) RO" -Path $userGroupLocation -Server $domain -PassThru
    $roResGroup = New-ADGroup -GroupScope DomainLocal -GroupCategory Security -Name "FP$($shortDomainName)_ISO_EDM_$($appID)_$($projectName)_RO" -Path $resourceGroupLocation -Server $domain -PassThru
    $adminResGroup = New-ADGroup -GroupScope DomainLocal -GroupCategory Security -Name "FP$($shortDomainName)_ISO_EDM_$($appID)_$($projectName)_RW" -Path $resourceGroupLocation -Server $domain -PassThru

    if ($createDataRoom -eq "Y"){
        Write-Host -ForegroundColor Cyan "Creating Standard Group : ACC$($shortDomainName)_EDM_$($appID)_$($projectName)_DataRoomRO"
        $dataroomRO = New-ADGroup -GroupScope Global -GroupCategory Security -Name "ACC$($shortDomainName)_EDM_$($appID)_$($projectName)_DataRoomRO" -Description "$($appID) $($projectName) RO" -Path $userGroupLocation -Server $domain -PassThru
        if ($dataroomRO){
            Write-Host -ForegroundColor Green "$($dataroomRO.SamAccountName) created successfully"
        }

        Write-Host -ForegroundColor Cyan "Creating Standard Group : ACC$($shortDomainName)_EDM_$($appID)_$($projectName)_DataRoomRW"
        $dataroomRW = New-ADGroup -GroupScope Global -GroupCategory Security -Name "ACC$($shortDomainName)_EDM_$($appID)_$($projectName)_DataRoomRW" -Description "$($appID) $($projectName) RW" -Path $userGroupLocation -Server $domain -PassThru
        if ($dataroomRW){
            Write-Host -ForegroundColor Green "$($dataroomRW.SamAccountName) created successfully"
        }

        Write-Host -ForegroundColor Cyan "Creating Standard Group : DG$($shortDomainName)_EDM_$($appID)_$($projectName)DataRoom"
        $dataroomResGroup = New-ADGroup -GroupScope DomainLocal -GroupCategory Security -Name "DG$($shortDomainName)_EDM_$($appID)_$($projectName)DataRoom" -Path $resourceGroupLocation -Server $domain -Description "$($appID) $($Project) DataRoom" -PassThru
        if ($dataroomResGroup){
            Write-Host -ForegroundColor Green "$($dataroomResGroup.SamAccountName) created successfully"
        }
    }

    #Write-Host -ForegroundColor Cyan "Nesting Groups"
    sleep 15
    Add-ADGroupMember -Identity $roResGroup.SamAccountName -Members $roUserGroup.SamAccountName -Server $domain
    Add-ADGroupMember -Identity $adminResGroup.SamAccountName -Members $adminUserGroup.SamAccountName -Server $domain
    Get-ADGroup DG$($shortDomainName)_EDM_$($appID)_Relativity -Server $domain | Add-ADGroupMember -Members $projectUserGroup.SamAccountName
    Get-ADGroup DG$($shortDomainName)_EDM_$($appID)_WelcomeMessage -Server $domain | Add-ADGroupMember -Members $projectUserGroup.SamAccountName
    Get-ADGroup RES$($shortDomainName)_Citrix_SHA_AllowPrint -Server $domain | Add-ADGroupMember -Members $allowPrintUserGroup.SamAccountName
    Get-ADGroup RES$($shortDomainName)_Citrix_SHA_AllowLocalDriveMap -Server $domain | Add-ADGroupMember -Members $allowMapDriveUserGroup.SamAccountName
    Get-ADGroup RES$($shortDomainName)_Citrix_SHA_AllowCopyPaste -Server $domain | Add-ADGroupMember -Members $allowCopyPasteUserGroup.SamAccountName

    if ($createDataRoom -eq "Y"){
        Write-Host -ForegroundColor Cyan "Nesting Group $dataroomResGroup into GPO_U_SHA_PrdXASettings"
        Get-ADGroup "GPO_U_SHA_PrdXASettings" -Server $domain | Add-ADGroupMember -Members $dataroomResGroup.SamAccountName

        Write-Host -ForegroundColor Cyan "Nesting Group $dataroomResGroup into GPO_U_EDM_REL01P_DataRoom"
        Get-ADGroup "GPO_U_EDM_REL01P_DataRoom" -Server $domain | Add-ADGroupMember -Members $dataroomResGroup.SamAccountName

        Write-Host -ForegroundColor Cyan "Nesting Group $dataroomResGroup into RESPRD_SHA_ManagementVDI_Users"
        Get-ADGroup "RESPRD_SHA_ManagementVDI_Users" -Server $domain | Add-ADGroupMember -Members $dataroomResGroup.SamAccountName

        Write-Host -ForegroundColor Cyan "Nesting Group $dataroomRO into FP$($shortDomainName)_ISO_EDM_$($appID)_$($projectName)_RO"
        Get-ADGroup "FP$($shortDomainName)_ISO_EDM_$($appID)_$($projectName)_RO" -Server $domain | Add-ADGroupMember -Members $dataroomRO.SamAccountName

        Write-Host -ForegroundColor Cyan "Nesting Group $dataroomRW into FP$($shortDomainName)_ISO_EDM_$($appID)_$($projectName)_RW"
        Get-ADGroup "FP$($shortDomainName)_ISO_EDM_$($appID)_$($projectName)_RW" -Server $domain | Add-ADGroupMember -Members $dataroomRW.SamAccountName

        Write-Host -ForegroundColor Cyan "Nesting Group $dataroomRO into $($dataroomResGroup.SamAccountName)"
        Get-ADGroup "$($dataroomResGroup.SamAccountName)" -Server $domain | Add-ADGroupMember -Members $dataroomRO.SamAccountName

        Write-Host -ForegroundColor Cyan "Nesting Group $dataroomRW into $($dataroomResGroup.SamAccountName)"
        Get-ADGroup "$($dataroomResGroup.SamAccountName)" -Server $domain | Add-ADGroupMember -Members $dataroomRW.SamAccountName
    }

} catch {
    $Error

}


