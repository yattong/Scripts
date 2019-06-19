############ 
# Find Matching Users for EDM in KPC
# 
############


# import csv
"Importing"
$data = Import-Csv "C:\Users\gpoon_adm\Documents\Migration\17-11-17_Output\Relativity_Users_v0.1.csv"


# Add another Column
"adding Columns"
$data = $data | Select *, @{Name="1xMatch";Expression={""}}
$data = $data | Select *, @{Name="3xMatch";Expression={""}}


########### Compare UserNames
"Comparing Username Data"

foreach ($line in $data){
    if(dsquery.exe user "dc=kpmgprod,dc=com" -samid $line.Username){
        "$($line.Username) - KPC AD User Exists"
        $line."1xMatch" = "TRUE"
        $user = Get-ADUser $line.Username -server kpmgprod.com -Properties *
        if (($user.SamAccountName -eq $line.Username) -and ($user.GivenName -eq $line.FirstName) -and ($user.surname -eq $line.LastName)){
            "$($user.Name) - KPC AD User is the correct user"
            $line."3xMatch" = "TRUE"
        }
    }
}


############ Compare Print Groups 
#"Getting Print Groups"
$adGroups = Get-ADGroup -filter {name -like "accprd*edm_rel01p_*print"} -Server kpmgprod.com | sort #Change entry to rel01p 1/3
$members = @()
foreach ($adGroup in $adGroups){
    $members += Get-ADGroupMember $adGroup.Name -Server kpmgprod.com
}

# Compare Data
"Comparing Print Permissions Data"
foreach ($line in $data){
    foreach ($member in $members){
        if ($member.SamAccountName -eq $line.Username){
            "$($line.Username) - matches : $($member.SamAccountName)"
            $line.KPCPrint = "TRUE"
        }
    }
}


############ Compare Drive Map Groups
#"Getting Drive Map Groups"
$adGroups = Get-ADGroup -filter {name -like "accprd*edm_rel01p_*DriveMap"} -Server kpmgprod.com | sort
$members = @()
foreach ($adGroup in $adGroups){
    $members += Get-ADGroupMember $adGroup.Name -Server kpmgprod.com
}

# Compare Data
"Comparing Drive Map Permissions Data"
foreach ($line in $data){
    foreach ($member in $members){
        if ($member.SamAccountName -eq $line.Username){
            "$($line.Username) - matches : $($member.SamAccountName)"
            $line.KPCDriveMap = "TRUE"
        }
    }
}

############
#"Getting Copy Paste Groups"
$adGroups = Get-ADGroup -filter {name -like "accprd*edm_rel01p_*Paste"} -Server kpmgprod.com | sort
$members = @()
foreach ($adGroup in $adGroups){
    $members += Get-ADGroupMember $adGroup.Name -Server kpmgprod.com
}

# Compare Data
"Comparing Copy Paste Permissions Data"
foreach ($line in $data){
    foreach ($member in $members){
        if ($member.SamAccountName -eq $line.Username){
            "$($line.Username) - matches : $($member.SamAccountName)"
            $line.KPCCopyPaste = "TRUE"
        }
    }
}



$data | Export-Csv "C:\Users\gpoon_adm\Documents\Migration\17-11-17_Output\Relativity_Users_v0.2.23-11-17.csv" -NoTypeInformation
