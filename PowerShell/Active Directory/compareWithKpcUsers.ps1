############ 
# Find Matching Users for EDM in KPC
# 
############

# import csv
"Importing"
$data = Import-Csv "C:\RelMig\REL9-Users-Exported-141117.csv"

# Add another Column
"adding Column"
$data = $data | Select *, @{Name="1xMatch";Expression={""}}
$data = $data | Select *, @{Name="3xMatch";Expression={""}}

# Ger Relgroups
#"Getting Groups"
#$adGroups = Get-ADGroup -filter {name -like "accprd*edm*project"} -Server kpmgprod.com | sort


#
"Comparing Data"
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

$data | Export-Csv "C:\RelMig\REL9-Users-Exported-141117 v0.1.csv" -NoTypeInformation

